defmodule Elastic.HTTP do
  @moduledoc ~S"""
  Used to make raw calls to Elastic Search.

  Each function returns a tuple indicating whether or not the request
  succeeded or failed (`:ok` or `:error`), the status code of the response,
  and then the processed body of the response.

  For example, a request like this:

  ```elixir
    Elastic.HTTP.get("/answer/_search")
  ```

  Would return a response like this:

  ```
    {:ok, 200,
     %{"_shards" => %{"failed" => 0, "successful" => 5, "total" => 5},
       "hits" => %{"hits" => [%{"_id" => "1", "_index" => "answer", "_score" => 1.0,
            "_source" => %{"text" => "I like using Elastic Search"}, "_type" => "answer"}],
         "max_score" => 1.0, "total" => 1}, "timed_out" => false, "took" => 7}}
  ```
  """

  alias Elastic.AWS
  alias Elastic.ResponseHandler
  alias Tesla.Env

  @type method ::
          :head
          | :get
          | :delete
          | :trace
          | :options
          | :post
          | :put
          | :patch
  @type url :: binary() | URI.t()

  @doc """
  Makes a request using the GET HTTP method, and can take a body.

  ```
  Elastic.HTTP.get("/answer/_search", body: %{query: ...})
  ```

  """
  @spec get(url(), Keyword.t()) :: ResponseHandler.result()
  def get(url, options \\ []) do
    request(:get, url, options)
  end

  @doc """
  Makes a request using the POST HTTP method, and can take a body.
  """
  @spec post(url(), Keyword.t()) :: ResponseHandler.result()
  def post(url, options \\ []) do
    request(:post, url, options)
  end

  @doc """
  Makes a request using the PUT HTTP method:

  ```
  Elastic.HTTP.put("/answers/answer/1", body: %{
    text: "I like using Elastic Search"
  })
  ```
  """
  @spec put(url(), Keyword.t()) :: ResponseHandler.result()
  def put(url, options \\ []) do
    request(:put, url, options)
  end

  @doc """
  Makes a request using the DELETE HTTP method:

  ```
  Elastic.HTTP.delete("/answers/answer/1")
  ```
  """
  @spec delete(url(), Keyword.t()) :: ResponseHandler.result()
  def delete(url, options \\ []) do
    request(:delete, url, options)
  end

  @doc """
  Makes a request using the HEAD HTTP method:

  ```
  Elastic.HTTP.head("/answers")
  ```
  """
  @spec head(url(), Keyword.t()) :: ResponseHandler.result()
  def head(url, options \\ []) do
    request(:head, url, options)
  end

  @spec bulk(Keyword.t()) :: ResponseHandler.result()
  def bulk(options) do
    body = Keyword.get(options, :body, "") <> "\n"
    options = Keyword.put(options, :body, body)
    request(:post, "_bulk", options)
  end

  @spec base_url() :: binary()
  defp base_url do
    base_url = Elastic.base_url()

    if is_binary(base_url) do
      base_url
    else
      "http://localhost:9200"
    end
  end

  @spec request(method(), url(), Keyword.t()) :: ResponseHandler.result()
  defp request(method, url, options) do
    body = Keyword.get(options, :body, []) |> encode_body
    timeout = Application.get_env(:elastic, :timeout, 30_000)
    url = URI.merge(base_url(), url)

    options =
      options
      |> Keyword.put_new(:headers, Keyword.new())
      |> Keyword.put(:body, body)
      |> Keyword.put(:timeout, timeout)
      |> Keyword.put(:method, method)
      |> Keyword.put(:url, URI.to_string(url))
      |> add_content_type_header
      |> add_aws_header(method, url, body)
      |> add_basic_auth

    client = Tesla.client([], Tesla.Adapter.Hackney)
    Tesla.request(client, options) |> process_response
  end

  @spec add_content_type_header(Keyword.t()) :: Keyword.t()
  defp add_content_type_header(options) do
    headers = Keyword.put(options[:headers], :"Content-Type", "application/json")
    Keyword.put(options, :headers, headers)
  end

  @spec add_aws_header(Keyword.t(), method, url(), binary()) :: Keyword.t()
  def add_aws_header(options, method, url, body) do
    if AWS.enabled?() do
      headers =
        AWS.authorization_headers(
          method,
          url,
          options[:headers],
          body
        )
        |> Enum.reduce(options[:headers], fn {header, value}, headers ->
          Keyword.put(headers, String.to_atom(header), value)
        end)

      Keyword.put(options, :headers, headers)
    else
      options
    end
  end

  @spec add_basic_auth(Keyword.t()) :: Keyword.t()
  def add_basic_auth(options) do
    basic_auth = Keyword.get(options, :basic_auth, Elastic.basic_auth())
    Keyword.put(options, :basic_auth, basic_auth)
  end

  @spec process_response(Env.result()) :: ResponseHandler.result()
  defp process_response(response) do
    ResponseHandler.process(response)
  end

  @spec encode_body(any()) :: binary()
  defp encode_body(body) when is_binary(body) do
    body
  end

  defp encode_body(body) when is_map(body) and body != %{} do
    {:ok, encoded_body} = Jason.encode(body)
    encoded_body
  end

  defp encode_body(_body) do
    ""
  end
end

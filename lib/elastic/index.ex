defmodule Elastic.Index do
  alias Elastic.HTTP
  alias Elastic.Query
  alias Elastic.ResponseHandler

  @moduledoc ~S"""
  Collection of functions to work with indices.
  """

  @doc """
  Helper function for getting the name of an index combined with the
  `index_prefix` and `mix_env` configuration.
  """
  @spec name(binary()) :: binary()
  def name(index) do
    [index_prefix(), mix_env(), index]
    |> Enum.reject(&(&1 == nil || &1 == ""))
    |> Enum.join("_")
  end

  @doc """
  Wrapper function, for constructing an ElasticSearch REST API URL
  from an already constructed path, query parameters, etc.
  """
  @spec url(binary()) :: binary()
  def url(path_query) do
    Elastic.base_url() <> "/" <> path_query
  end

  @doc """
  Creates the specified index.
  If you've configured `index_prefix` and `use_mix_env` for Elastic, it will use those.

  ## Examples

  ```elixir
  # With index_prefix set to 'elastic'
  # And with `use_mix_env` set to `true`
  # This will create the `elastic_dev_answer` index
  Elastic.Index.create("answer")
  ```
  """
  @spec create(binary()) :: ResponseHandler.result()
  def create(index) do
    HTTP.put(name(index) |> url)
  end

  @doc """
  Creates the specified index with optional configuration parameters like settings,
  mappings, aliases (see the ES Indices API documentation for information on what
  you can pass).
  If you've configured `index_prefix` and `use_mix_env` for Elastic, it will use those.

  ## Examples

  ```elixir
  # With index_prefix set to 'elastic'
  # And with `use_mix_env` set to `true`
  # This will create the `elastic_dev_answer` index
  Elastic.Index.create("answer", %{settings: {number_of_shards: 2}})
  ```
  """

  @spec create(binary(), any()) :: ResponseHandler.result()
  def create(index, parameters) do
    HTTP.put(name(index) |> url, body: parameters)
  end

  @doc """
  Deletes the specified index.
  If you've configured `index_prefix` and `use_mix_env` for Elastic, it will use those.

  ## Examples

  ```elixir
  # With index_prefix set to 'elastic'
  # And with `use_mix_env` set to `true`
  # This will delete the `elastic_dev_answer` index
  Elastic.Index.delete("answer")
  ```

  """
  @spec delete(binary()) :: ResponseHandler.result()
  def delete(index) do
    index |> name |> url |> HTTP.delete()
  end

  @doc """
  Refreshes the specified index by issuing a [refresh HTTP call](https://www.elastic.co/guide/en/elasticsearch/reference/current/indices-refresh.html).
  """
  @spec refresh(binary()) :: ResponseHandler.result()
  def refresh(index) do
    HTTP.post("#{name(index)}/_refresh" |> url)
  end

  @doc """
  Checks if the specified index exists.
  The index name will be automatically prefixed as per this package's configuration.
  """
  @spec exists?(binary()) :: boolean()
  def exists?(index) do
    {_, status, _} = index |> name |> url |> HTTP.head()
    status == 200
  end

  @doc """
  Opens the specified index.
  """
  @spec open(binary()) :: ResponseHandler.result()
  def open(index) do
    HTTP.post("#{name(index)}/_open" |> url)
  end

  @doc """
  Closes the specified index.
  """
  @spec close(binary()) :: ResponseHandler.result()
  def close(index) do
    HTTP.post("#{name(index)}/_close" |> url)
  end

  @doc false
  @spec search(Query.t()) :: ResponseHandler.result()
  def search(%Query{index: index, body: body}) do
    HTTP.get("#{name(index)}/_search" |> url, body: body)
  end

  @doc false
  @spec count(Query.t()) :: ResponseHandler.result()
  def count(%Query{index: index, body: body}) do
    HTTP.get("#{name(index)}/_count" |> url, body: body)
  end

  @spec index_prefix() :: term()
  defp index_prefix do
    Application.get_env(:elastic, :index_prefix)
  end

  @spec mix_env() :: atom() | nil
  defp mix_env do
    if Application.get_env(:elastic, :use_mix_env),
      do: Mix.env(),
      else: nil
  end
end

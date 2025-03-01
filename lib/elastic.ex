defmodule Elastic do
  @moduledoc ~S"""

  Elastic is a thin veneer over Tesla to help you talk to your Elastic Search stores.

  Elastic provides five main ways of talking to the stores:

  * `Elastic.Document.API`: Adds functions to a module to abstract away some of the mess of actions on an index.
  * `Elastic.Index`: Functions for working with indexes.
  * `Elastic.Bulk`: Provides functions for bulk creating or updating documents in an ElasticSearch store.
  * `Elastic.Scroller`: A server which works with Elastic Search's [Scroll API](https://www.elastic.co/guide/en/elasticsearch/reference/2.4/search-request-scroll.html).
  * `Elastic.HTTP`: A very thin veneer / low-level API over Tesla and Jason to make queries to your Elastic Search store.

  ## Configuration

  You can configure the way Elastic behaves by using the following configuration options:

  * `base_url`: Where your Elastic Search instance is located. Defaults to http://localhost:9200.
  * `index_prefix`: A prefix to use for all indexes. Only used when using the Document API, or `Elastic.Index`.
  * `use_mix_env`: Adds `Mix.env` to an index, so that the index name used is something like `dev_answer`. Can be used in conjunction with `index_prefix` to get things like `company_dev_answer` as the index name.
  * `timeout`: How long to wait before timing out requests. Default is 30 seconds.

  ### AWS Configuration

  If your Elastic Search store is hosted on AWS, there are configuration options for that:

  ```elixir
  config :elastic,
    base_url: "https://your-amazon-es-endpoint-goes-here",
    basic_auth: {"username", "password"},
    aws: %{
      enabled: true,
      access_key_id: "ACCESS_KEY_ID_GOES_HERE",
      secret_access_key: "SECRET_ACCESS_KEY_GOES_HERE",
      region: "REGION_GOES_HERE"
    }
  ```

  Elastic will then use the `AWSAuth` library to sign URLs for requests to this store.
  """

  @spec base_url() :: term()
  def base_url do
    url = Application.get_env(:elastic, :base_url)

    if is_binary(url) do
      url
    else
      "http://localhost:9200"
    end
  end

  @spec base_kibana_url() :: term()
  def base_kibana_url do
    url = Application.get_env(:elastic, :base_kibana_url)

    if is_binary(url) do
      url
    else
      "http://localhost:5601"
    end
  end

  @spec basic_auth() :: term()
  def basic_auth do
    Application.get_env(:elastic, :basic_auth)
  end
end

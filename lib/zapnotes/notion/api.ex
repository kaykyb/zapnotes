defmodule Zapnotes.Notion.Api do
  def create_page(parent, properties, children) do
    body = %{
      parent: parent,
      properties: properties,
      children: children
    }

    with {:ok, res} <-
           Req.post(base_req(),
             url: "/pages",
             json: body,
             receive_timeout: 120_000,
             connect_options: [
               timeout: 120_000
             ]
           ),
         :ok <- ensure_status(res) do
      {:ok, res.body["url"]}
    end
  end

  defp base_req() do
    Req.new(
      base_url: "https://api.notion.com/v1",
      headers: default_headers()
    )
  end

  defp default_headers() do
    %{
      "Authorization" => "Bearer #{integration_secret()}",
      "Accept" => "application/json",
      "Notion-Version" => "2022-06-28"
    }
  end

  defp ensure_status(res) when res.status in 200..299 do
    :ok
  end

  defp ensure_status(res) do
    {:error, res}
  end

  defp integration_secret() do
    :zapnotes
    |> Application.fetch_env!(Zapnotes.Notion)
    |> Keyword.fetch!(:integration_secret)
  end
end

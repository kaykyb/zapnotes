defmodule Zapnotes.Whatsapp.Api do
  def send_template_message(to_phone, template_name) do
    body = %{
      messaging_product: "whatsapp",
      to: to_phone,
      type: "template",
      template: %{
        name: template_name,
        language: %{code: "en"}
      }
    }

    with {:ok, res} <-
           Req.post(base_req(),
             url: "/#{config(:phone_id)}/messages",
             json: body,
             receive_timeout: 120_000,
             connect_options: [
               timeout: 120_000
             ]
           ),
         :ok <- ensure_status(res) do
      :ok
    end
  end

  def fetch_media(media_id) do
    with {:ok, res} <- Req.get(base_req(), url: "/#{media_id}"),
         :ok <- ensure_status(res) do
      {:ok, res.body}
    end
  end

  def download_whatsapp_media(media_url) do
    res =
      Req.get(
        media_url,
        headers: %{
          "Authorization" => "Bearer #{config(:access_token)}"
        }
      )

    with {:ok, res} <- res,
         :ok <- ensure_status(res) do
      {:ok, res.body}
    end
  end

  defp base_req() do
    Req.new(
      base_url: "https://graph.facebook.com/v18.0",
      headers: default_headers()
    )
  end

  defp default_headers() do
    %{
      "Authorization" => "Bearer #{config(:access_token)}",
      "Accept" => "application/json"
    }
  end

  defp ensure_status(res) when res.status in 200..299 do
    :ok
  end

  defp ensure_status(res) do
    {:error, res}
  end

  defp config(key) do
    :zapnotes
    |> Application.fetch_env!(Zapnotes.Whatsapp)
    |> Keyword.fetch!(key)
  end
end

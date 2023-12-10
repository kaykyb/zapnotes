defmodule ZapnotesWeb.Webhook.WhatsappController do
  use Phoenix.Controller

  alias Zapnotes.Whatsapp

  def verify(conn, %{
        "hub.mode" => "subscribe",
        "hub.verify_token" => token,
        "hub.challenge" => challenge
      }) do
    with :ok <- Whatsapp.validate_verify_token(token) do
      conn
      |> put_status(200)
      |> text(challenge)
    end
  end

  def receive(conn, %{"entry" => _entries} = payload) do
    [signature] = get_req_header(conn, "x-hub-signature-256")
    [raw_body] = conn.private[:raw_body]

    with :ok <- Whatsapp.validate_webhook_payload(raw_body, signature),
         :ok <- Whatsapp.handle_webhook_payload(payload) do
      conn
      |> put_status(200)
      |> text("OK")
    end
  end
end

defmodule Zapnotes.Accounts.User do
  alias Zapnotes.Chats
  use Ecto.Schema

  @primary_key {:id, :binary_id, autogenerate: true}

  schema "users" do
    field :platform, Ecto.Enum, values: [:whatsapp]
    field :platform_uid, :string

    has_many :chat_messages, Chats.Message

    timestamps()
  end
end

defmodule Zapnotes.Chats.Message do
  use Ecto.Schema

  alias Zapnotes.Accounts

  @primary_key {:id, :binary_id, autogenerate: true}

  schema "chat_messages" do
    field :platform, Ecto.Enum, values: [:whatsapp]
    field :platform_id, :string

    field :text, :string
    field :audio_url, :string

    belongs_to :user, Accounts.User, type: :binary_id

    timestamps()
  end
end

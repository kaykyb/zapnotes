defmodule Zapnotes.Whatsapp.Webhook do
  defmodule Entry do
    alias Zapnotes.Whatsapp.Webhook.Change

    @derive Jason.Encoder
    @enforce_keys [:id, :changes]
    defstruct [:id, :changes]

    @type t :: %__MODULE__{
            id: String.t(),
            changes: list(Change.t())
          }

    def from_map(%{"id" => id, "changes" => changes}) do
      parsed_changes = Enum.map(changes, &Change.from_map/1)
      %__MODULE__{id: id, changes: parsed_changes}
    end
  end

  defmodule Change do
    alias Zapnotes.Whatsapp.Webhook.ChangeValue

    @derive Jason.Encoder
    @enforce_keys [:value, :field]
    defstruct [:value, :field]

    @type t :: %__MODULE__{
            value: ChangeValue.t(),
            field: String.t()
          }

    def from_map(%{"value" => value, "field" => field}) do
      parsed_value = ChangeValue.from_map(value)
      %__MODULE__{value: parsed_value, field: field}
    end
  end

  defmodule ChangeValue do
    alias Zapnotes.Whatsapp.Webhook.Message

    @derive Jason.Encoder
    @enforce_keys [:messaging_product, :messages]
    defstruct [:messaging_product, :messages]

    @type t :: %__MODULE__{
            messaging_product: String.t(),
            messages: list(Message.t())
          }

    def from_map(%{"messaging_product" => messaging_product, "messages" => messages}) do
      parsed_messages = Enum.map(messages, &Message.from_map/1)
      %__MODULE__{messaging_product: messaging_product, messages: parsed_messages}
    end

    def from_map(%{"messaging_product" => messaging_product}) do
      %__MODULE__{messaging_product: messaging_product, messages: []}
    end
  end

  defmodule Message do
    @derive Jason.Encoder
    @enforce_keys [:id, :from, :timestamp, :type]
    defstruct [:id, :from, :timestamp, :type, :audio, :text]

    @type t :: %__MODULE__{
            id: String.t(),
            from: String.t(),
            timestamp: integer(),
            type: String.t(),
            audio: Audio.t() | nil,
            text: Text.t() | nil
          }

    defmodule Audio do
      @derive Jason.Encoder
      @enforce_keys [:id, :mime_type]
      defstruct [:id, :mime_type]

      @type t :: %__MODULE__{
              id: String.t(),
              mime_type: String.t()
            }

      def from_map(%{"id" => id, "mime_type" => mime_type}) do
        %__MODULE__{id: id, mime_type: mime_type}
      end
    end

    defmodule Text do
      @derive Jason.Encoder
      @enforce_keys [:body]
      defstruct [:body]

      @type t :: %__MODULE__{
              body: String.t()
            }

      def from_map(%{"body" => body}) do
        %__MODULE__{body: body}
      end
    end

    def from_map(%{"id" => id, "from" => from, "timestamp" => timestamp, "type" => type} = params) do
      timestamp =
        if is_integer(timestamp) do
          timestamp
        else
          {timestamp, _} = Integer.parse(timestamp)
          timestamp
        end

      base = %__MODULE__{id: id, from: from, timestamp: timestamp, type: type}

      case type do
        "audio" ->
          parsed_audio = Audio.from_map(params["audio"])
          Map.put(base, :audio, parsed_audio)

        "text" ->
          parsed_text = Text.from_map(params["text"])
          Map.put(base, :text, parsed_text)

        _ ->
          base
      end
    end
  end

  @spec entries_from_map(list(map())) :: list(Entry.t())
  def entries_from_map(entries) do
    Enum.map(entries, &Entry.from_map/1)
  end

  @spec messages_from_entries(list(Entry.t())) :: list(Message.t())
  def messages_from_entries(entries) do
    entries
    |> Enum.flat_map(& &1.changes)
    |> Enum.flat_map(fn
      %Change{field: "messages", value: %ChangeValue{messages: messages}} -> messages
      %Change{} -> []
    end)
  end
end

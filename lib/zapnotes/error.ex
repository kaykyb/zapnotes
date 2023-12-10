defmodule Zapnotes.Error do
  defmodule ServiceError do
    @derive Jason.Encoder
    @enforce_keys [:code, :message, :service]
    defexception [:code, :message, :service]

    @type t :: %__MODULE__{
            code: String.t(),
            message: String.t(),
            service: atom()
          }

    @impl Exception
    def exception(opts) do
      service = Keyword.fetch!(opts, :service)
      base_message = Keyword.get(opts, :message, "Failed request")
      message = "[#{service}] #{base_message}"

      %__MODULE__{
        code: opts[:code],
        message: message,
        service: service
      }
    end
  end

  @spec service([opt]) :: ServiceError.t()
        when opt: {:code, String.t()} | {:message, String.t()} | {:service, atom()}
  def service(opts), do: ServiceError.exception(opts)
end

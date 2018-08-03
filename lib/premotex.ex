defmodule Premotex do
  @moduledoc """
  Preloads remote files at Elixir compilation and makes them available in runtime.

  Example:

      iex> defmodule MyFiles do
      iex>   use Premotex
      iex>   defremotefile(:my_image, "http://www.gstatic.com/webp/gallery/1.jpg")
      iex> end
      iex>
      iex> MyFiles.remote_file_path(:my_image) |> String.split("/") |> List.last
      "my_image.jpg"

  """

  defmacro __using__(_) do
    quote do
      import Premotex
    end
  end

  defmacro defremotefile(defined_name, url) do
    Application.ensure_all_started(:inets)
    Application.ensure_all_started(:ssl)

    IO.puts("Downloading remote file #{inspect(defined_name)}...")

    filename =
      case Path.extname(to_string(defined_name)) do
        "" -> "#{defined_name}#{Path.extname(url)}"
        _ -> "#{defined_name}"
      end

    url_chars = String.to_charlist(url)
    file_path = "#{files_dir()}/#{filename}"
    {:ok, resp} = :httpc.request(:get, {url_chars, []}, [], body_format: :binary)
    {{_, 200, 'OK'}, _headers, body} = resp

    File.write!(file_path, body)

    quote do
      def remote_file_path(unquote(defined_name)), do: unquote(file_path)
    end
  end

  def files_dir do
    case Application.fetch_env(:premotex, :files_dir) do
      {:ok, dir} when not is_nil(dir) -> dir
      _ -> Application.app_dir(:premotex, "priv/files")
    end
  end
end

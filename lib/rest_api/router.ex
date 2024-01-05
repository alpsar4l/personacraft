defmodule RestApi.Router do
  use Plug.Router

  plug(Plug.Logger)

  plug(:match)

  plug(Plug.Parsers,
    parsers: [:json],
    pass: ["application/json"],
    json_decoder: Jason
  )

  plug(:dispatch)

  @personalities_path "data/personalities.json"

  defp load_personalities do
    with {:ok, content} <- File.read(@personalities_path),
         {:ok, decoded_content} = Jason.decode(content),
         names = decoded_content["names"],
         surnames = decoded_content["surnames"],
         jobs = decoded_content["jobs"] do
      {:ok, names, surnames, jobs}
    else
      {:error, reason} ->
        {:error, "Failed to load names: #{reason}"}
    end
  end

  defp select_random([]), do: nil
  defp select_random(items) do
    [item | _rest] = Enum.shuffle(items)
    "#{item}"
  end

  defp generate_random_number do
    :rand.uniform(64) + 7
  end

  get "/" do
    case load_personalities() do
      {:ok, names, surnames, jobs} ->
        name = select_random(names)
        surname = select_random(surnames)
        job = select_random(jobs)

        data = %{
          full_name: "#{name} #{surname}",
          name: name,
          surname: surname,
          job: job,
          age: generate_random_number()
        }

        send_resp(conn, 200, case Jason.encode(data) do
                              {:ok, encoded} -> encoded
                              {:error, _reason} -> "Failed to encode data"
                            end)
      {:error, _reason} ->
        send_resp(conn, 500, "Internal Server Error")
    end
  end

  match _ do
    send_resp(conn, 404, "Not Found")
  end
end

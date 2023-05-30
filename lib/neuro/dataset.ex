defmodule Neuro.Dataset do
  @moduledoc "Dataset management for Neuro"

  alias Vix.Vips.Image, as: VixImage

  def generate_image(char) do
    with vix_image <- make_image(char) |> IO.inspect(label: "vix_image"),
         image_path <- upload_path() <> "/#{char}.jpg",
         :ok <- VixImage.write_to_file(vix_image, image_path) do
      image_path
      |> prepare_image()
      |> Nx.new_axis(0)
      |> Nx.to_list()
      |> Nx.tensor()
    end
  end

  def generate do
    with charlist <- charlist(),
         vix_images <- make_images(charlist),
         path <- path() do
      images_tensors =
        vix_images
        |> Enum.with_index()
        |> Enum.map(fn {image, index} ->
          image_path = path <> "/#{Enum.at(charlist, index)}.jpg"

          case VixImage.write_to_file(image, image_path) do
            :ok ->
              image_path
              |> prepare_image()
              |> Nx.new_axis(0)
              |> Nx.to_list()

            _ ->
              raise "could not write to #{image_path}"
          end
        end)
        |> Nx.tensor()

      {images_tensors, charlist |> charlist_tensor()} |> List.wrap()
    end
  end

  def prepare_image(path) do
    path
    |> Evision.imread(flags: Evision.Constant.cv_IMREAD_GRAYSCALE())
    |> Evision.resize({28, 28})
    |> Evision.Mat.to_nx()
    |> Nx.backend_transfer()
  end

  def charlist do
    characters = for char <- ?A..?Z, do: [char]
    numbers = for number <- 0..9, do: Integer.to_charlist(number)
    characters |> Enum.concat(numbers) |> Enum.map(&List.to_string/1)
  end

  def charlist_tensor(charlist) do
    char_range = 0..(Enum.count(charlist) - 1)

    char_range
    |> Enum.to_list()
    |> Nx.tensor()
    |> Nx.new_axis(-1)
    |> Nx.equal(Nx.tensor(Enum.to_list(char_range)))
  end

  def to_character(number) do
    charlist() |> Enum.at(number)
  end

  defp make_images(charlist) do
    for(char <- charlist, do: make_image(char))
  end

  defp make_image(char) do
    Image.Text.text!(char,
      background_fill_color: :black,
      text_fill_color: :white,
      font_size: 200,
      padding: 80
    )
  end

  def path do
    Path.join(Application.app_dir(:neuro, "priv"), "dataset")
  end

  def upload_path do
    Path.join(Application.app_dir(:neuro, "priv"), "upload")
  end

  def clean_uploads do
    upload_path = upload_path()

    File.ls(upload_path)
    |> elem(1)
    |> Enum.each(fn file ->
      full_path = Path.join(upload_path, file)
      File.rm(full_path)
    end)

    :ok
  end
end

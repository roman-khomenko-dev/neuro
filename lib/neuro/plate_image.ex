defmodule Neuro.PlateImage do
  @moduledoc "Image car plate recognition"

  @min_area 1000
  @max_area 10_000

  # Neuro.PlateImage.recognize
  def recognize do
    original_image =
      Evision.imread(path_image())
      |> IO.inspect(label: "original_image")

    image = original_image |> transform() |> IO.inspect(label: "transformed image")

    element = Evision.getStructuringElement(Evision.Constant.cv_MORPH_RECT(), {3, 3})
    morph_image = Evision.morphologyEx(image, Evision.Constant.cv_MORPH_CLOSE(), element)
    true = Evision.imwrite(path_test(), morph_image)

    contours = detect_contours(morph_image)

    countered_image =
      path_image()
      |> Evision.imread()
      |> Evision.drawContours(contours, -1, {0, 0, 255}, thickness: 1)

    true = Evision.imwrite(path_countered(), countered_image)

    # TODO write number plate rectangle cutting

    path_test() |> TesseractOcr.read() |> parse_string()
  end

  def transform(image) do
    image
    |> Evision.gaussianBlur({5, 5}, 1)
    |> Evision.cvtColor(6)
    |> Evision.laplacian(1, kernel: 1)
    |> Evision.UMat.get()
    |> Evision.threshold(15, 75, Evision.Constant.cv_THRESH_BINARY())
    |> elem(1)
    |> Evision.UMat.get()
    |> then(&Evision.Mat.as_type(&1, :u8))
  end

  def detect_contours(image) do
    Evision.findContours(
      image,
      Evision.Constant.cv_RETR_LIST(),
      Evision.Constant.cv_CHAIN_APPROX_NONE()
    )
    |> elem(0)
    |> Enum.reject(&validate_contour_area/1)
  end

  def validate_contour_area(contour) do
    area = Evision.contourArea(contour)
    area < @min_area or area > @max_area
  end

  def ratio_check(ar, breatth, height) do
    ratio = breatth / height

    ratio = if ratio < 1, do: div(1, ratio), else: ratio

    !(ar > 73862.5 || ratio > 6)
  end

  def ratio_and_rotation(rect) do
    {_, {breatth, height}, rect_angle} = rect

    angle = if breatth > height, do: -rect_angle, else: 90 + rect_angle

    case angle > 15 || (height == 0 or breatth == 0) do
      true ->
        false

      false ->
        breatth
        |> Kernel.*(height)
        |> ratio_check(breatth, height)
    end
  end

  def parse_string(input) do
    case String.split(input, "\n\n") do
      [number, subtitle | _] -> %{number: extract_alphanumeric(number), subtitle: subtitle}
      _ -> nil
    end
  end

  defp extract_alphanumeric(string) do
    String.replace(string, ~r/[^A-Za-z0-9]/, "")
  end

  defp path_image, do: Path.join(Application.app_dir(:neuro, "priv"), "car_image.jpg")

  defp path_plate, do: Path.join(Application.app_dir(:neuro, "priv"), "plate_image.jpg")

  defp path_test, do: Path.join(Application.app_dir(:neuro, "priv"), "test.jpg")

  defp path_countered, do: Path.join(Application.app_dir(:neuro, "priv"), "countered.jpg")
end

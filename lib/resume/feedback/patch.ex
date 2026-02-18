defmodule Resume.Feedback.Patch do
  @moduledoc """
  Applies delta operations to a resume data map.

  Operations are 0-indexed and best-effort: invalid ops are skipped with a warning.
  """

  require Logger

  @top_level_scalars ~w(summary)
  @array_sections ~w(
    work_experience education skills certifications
    projects publications volunteer_work languages awards
  )

  @doc """
  Applies a list of operations to a resume data map, returning the updated map.

  ## Operations

  | Op                | Fields                              |
  |-------------------|-------------------------------------|
  | `replace`         | `section`, `value`                  |
  | `replace_item`    | `section`, `index`, `field`, `value`|
  | `replace_item`    | `section`, `index`, `value` (map)   |
  | `replace_section` | `section`, `value` (list)           |
  | `add_item`        | `section`, `value` (map)            |
  | `remove_item`     | `section`, `index`                  |
  """
  def apply(data, operations) when is_map(data) and is_list(operations) do
    Enum.reduce(operations, data, fn op, acc ->
      case apply_op(acc, op) do
        {:ok, updated} -> updated
        :skip -> acc
      end
    end)
  end

  defp apply_op(data, %{"op" => "replace", "section" => section, "value" => value})
       when section in @top_level_scalars do
    {:ok, Map.put(data, section, value)}
  end

  defp apply_op(data, %{
         "op" => "replace_item",
         "section" => section,
         "index" => index,
         "field" => field,
         "value" => value
       })
       when section in @array_sections and is_integer(index) do
    with {:ok, list} <- get_array(data, section),
         {:ok, item} <- get_at(list, index) do
      updated_item = Map.put(item, field, value)
      {:ok, Map.put(data, section, List.replace_at(list, index, updated_item))}
    end
  end

  defp apply_op(data, %{
         "op" => "replace_item",
         "section" => section,
         "index" => index,
         "value" => value
       })
       when section in @array_sections and is_integer(index) and is_map(value) do
    with {:ok, list} <- get_array(data, section),
         {:ok, _item} <- get_at(list, index) do
      {:ok, Map.put(data, section, List.replace_at(list, index, value))}
    end
  end

  defp apply_op(data, %{
         "op" => "replace_section",
         "section" => section,
         "value" => value
       })
       when section in @array_sections and is_list(value) do
    {:ok, Map.put(data, section, value)}
  end

  defp apply_op(data, %{"op" => "add_item", "section" => section, "value" => value})
       when section in @array_sections and is_map(value) do
    list = Map.get(data, section, [])
    {:ok, Map.put(data, section, list ++ [value])}
  end

  defp apply_op(data, %{"op" => "remove_item", "section" => section, "index" => index})
       when section in @array_sections and is_integer(index) do
    with {:ok, list} <- get_array(data, section),
         {:ok, _item} <- get_at(list, index) do
      {:ok, Map.put(data, section, List.delete_at(list, index))}
    end
  end

  defp apply_op(_data, op) do
    Logger.warning("Skipping invalid patch operation: #{inspect(op)}")
    :skip
  end

  defp get_array(data, section) do
    case Map.get(data, section) do
      list when is_list(list) -> {:ok, list}
      _ -> skip_warn("Section #{inspect(section)} is not an array")
    end
  end

  defp get_at(list, index) when index >= 0 and index < length(list) do
    {:ok, Enum.at(list, index)}
  end

  defp get_at(_list, index) do
    skip_warn("Index #{index} out of bounds")
  end

  defp skip_warn(msg) do
    Logger.warning("Patch skipped: #{msg}")
    :skip
  end
end

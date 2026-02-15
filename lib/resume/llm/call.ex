defmodule Resume.LLM.Call do
  @moduledoc """
  Ecto schema for tracking LLM API calls and their costs.

  Append-only — no `updated_at` timestamp.
  """

  use Ecto.Schema
  import Ecto.Changeset

  schema "llm_calls" do
    field :user_id, :id
    field :caller, :string
    field :model, :string
    field :input_tokens, :integer, default: 0
    field :output_tokens, :integer, default: 0
    field :cache_creation_input_tokens, :integer, default: 0
    field :cache_read_input_tokens, :integer, default: 0
    field :cost_cents, :float, default: 0.0
    field :duration_ms, :integer, default: 0

    timestamps(updated_at: false)
  end

  @required_fields ~w(model)a
  @optional_fields ~w(user_id caller input_tokens output_tokens cache_creation_input_tokens cache_read_input_tokens cost_cents duration_ms)a

  def changeset(call, attrs) do
    call
    |> cast(attrs, @required_fields ++ @optional_fields)
    |> validate_required(@required_fields)
  end
end

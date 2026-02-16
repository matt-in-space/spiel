defmodule Resume.FactsTest do
  use Resume.DataCase, async: true

  alias Resume.Facts

  describe "extract/3" do
    test "returns structured operations via LLM" do
      assert {:ok, operations} =
               Facts.extract(["I worked at Acme Corp"], "their career background")

      assert is_list(operations)
      assert %{"type" => "add", "text" => "Mock fact about career"} in operations
      assert %{"type" => "add", "text" => "Mock fact about skills"} in operations
    end
  end

  describe "parse_operations/1" do
    test "parses structured operation objects" do
      input =
        ~s([{"type": "add", "text": "fact one"}, {"type": "update", "index": 2, "text": "fact two"}])

      assert [
               %{"type" => "add", "text" => "fact one"},
               %{"type" => "update", "index" => 2, "text" => "fact two"}
             ] = Facts.parse_operations(input)
    end

    test "converts flat array of strings to add operations (backwards compat)" do
      assert [%{"type" => "add", "text" => "fact one"}, %{"type" => "add", "text" => "fact two"}] =
               Facts.parse_operations(~s(["fact one", "fact two"]))
    end

    test "filters out invalid operation objects" do
      input = ~s([{"type": "add", "text": "valid"}, {"bad": true}, {"type": "add"}])

      assert [%{"type" => "add", "text" => "valid"}] = Facts.parse_operations(input)
    end

    test "falls back to line splitting for non-JSON" do
      input = "First fact\nSecond fact\nThird fact"

      assert [
               %{"type" => "add", "text" => "First fact"},
               %{"type" => "add", "text" => "Second fact"},
               %{"type" => "add", "text" => "Third fact"}
             ] = Facts.parse_operations(input)
    end

    test "strips bullet prefixes in fallback mode" do
      input = "- First fact\n* Second fact"

      assert [
               %{"type" => "add", "text" => "First fact"},
               %{"type" => "add", "text" => "Second fact"}
             ] = Facts.parse_operations(input)
    end

    test "handles empty input" do
      assert [] = Facts.parse_operations("")
    end

    test "strips markdown code fence around JSON" do
      input = ~s(```json\n[{"type": "add", "text": "fact one"}]\n```)

      assert [%{"type" => "add", "text" => "fact one"}] = Facts.parse_operations(input)
    end

    test "strips code fence with no language tag" do
      input = ~s(```\n[{"type": "add", "text": "fact one"}]\n```)

      assert [%{"type" => "add", "text" => "fact one"}] = Facts.parse_operations(input)
    end

    test "handles code-fenced non-JSON lines" do
      input = "```\nFirst fact\nSecond fact\n```"

      assert [
               %{"type" => "add", "text" => "First fact"},
               %{"type" => "add", "text" => "Second fact"}
             ] = Facts.parse_operations(input)
    end
  end

  describe "apply_changes/2" do
    test "applies add operations" do
      {facts, descriptions} =
        Facts.apply_changes(["existing"], [%{"type" => "add", "text" => "new fact"}])

      assert facts == ["existing", "new fact"]
      assert [desc] = descriptions
      assert desc =~ "Added"
      assert desc =~ "new fact"
    end

    test "applies update operations" do
      {facts, descriptions} =
        Facts.apply_changes(
          ["old fact 1", "old fact 2"],
          [%{"type" => "update", "index" => 2, "text" => "updated fact 2"}]
        )

      assert facts == ["old fact 1", "updated fact 2"]
      assert [desc] = descriptions
      assert desc =~ "Updated #2"
    end

    test "applies remove operations" do
      {facts, descriptions} =
        Facts.apply_changes(
          ["fact 1", "fact 2", "fact 3"],
          [%{"type" => "remove", "index" => 2}]
        )

      assert facts == ["fact 1", "fact 3"]
      assert [desc] = descriptions
      assert desc =~ "Removed #2"
    end

    test "ignores out-of-bounds update" do
      {facts, descriptions} =
        Facts.apply_changes(
          ["only fact"],
          [%{"type" => "update", "index" => 5, "text" => "won't apply"}]
        )

      assert facts == ["only fact"]
      assert descriptions == []
    end

    test "ignores out-of-bounds remove" do
      {facts, descriptions} =
        Facts.apply_changes(["only fact"], [%{"type" => "remove", "index" => 5}])

      assert facts == ["only fact"]
      assert descriptions == []
    end

    test "applies mixed operations in order" do
      {facts, descriptions} =
        Facts.apply_changes(
          ["fact A", "fact B"],
          [
            %{"type" => "update", "index" => 1, "text" => "fact A updated"},
            %{"type" => "add", "text" => "fact C"}
          ]
        )

      assert facts == ["fact A updated", "fact B", "fact C"]
      assert length(descriptions) == 2
    end

    test "handles empty operations" do
      {facts, descriptions} = Facts.apply_changes(["fact 1"], [])
      assert facts == ["fact 1"]
      assert descriptions == []
    end

    test "handles empty facts" do
      {facts, descriptions} =
        Facts.apply_changes([], [%{"type" => "add", "text" => "first fact"}])

      assert facts == ["first fact"]
      assert length(descriptions) == 1
    end
  end
end

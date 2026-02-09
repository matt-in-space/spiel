defmodule Resume.FactsTest do
  use Resume.DataCase, async: true

  alias Resume.Facts

  describe "extract/2" do
    test "returns parsed facts via LLM" do
      assert {:ok, facts} = Facts.extract(["I worked at Acme Corp"], "their career background")
      assert is_list(facts)
      assert "Mock fact about career" in facts
      assert "Mock fact about skills" in facts
    end
  end

  describe "parse_facts/1" do
    test "parses valid JSON array of strings" do
      assert ["fact one", "fact two"] =
               Facts.parse_facts(~s(["fact one", "fact two"]))
    end

    test "filters out non-string values from JSON array" do
      assert ["only strings"] =
               Facts.parse_facts(~s(["only strings", 123, null, true]))
    end

    test "falls back to line splitting for non-JSON" do
      input = "First fact\nSecond fact\nThird fact"
      assert ["First fact", "Second fact", "Third fact"] = Facts.parse_facts(input)
    end

    test "strips bullet prefixes in fallback mode" do
      input = "- First fact\n* Second fact"
      assert ["First fact", "Second fact"] = Facts.parse_facts(input)
    end

    test "handles empty input" do
      assert [] = Facts.parse_facts("")
    end

    test "strips markdown code fence around JSON" do
      input = "```json\n[\"fact one\", \"fact two\"]\n```"
      assert ["fact one", "fact two"] = Facts.parse_facts(input)
    end

    test "strips code fence with no language tag" do
      input = "```\n[\"fact one\"]\n```"
      assert ["fact one"] = Facts.parse_facts(input)
    end

    test "handles code-fenced non-JSON lines" do
      input = "```\nFirst fact\nSecond fact\n```"
      assert ["First fact", "Second fact"] = Facts.parse_facts(input)
    end

    test "strips bare JSON array brackets and quoted strings in fallback" do
      input = "[\n  \"Led a team of 5\",\n  \"Built a data pipeline\"\n]"
      assert ["Led a team of 5", "Built a data pipeline"] = Facts.parse_facts(input)
    end
  end
end

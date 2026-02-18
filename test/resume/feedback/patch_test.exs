defmodule Resume.Feedback.PatchTest do
  use ExUnit.Case, async: true

  alias Resume.Feedback.Patch

  @base_data %{
    "summary" => "Experienced engineer.",
    "work_experience" => [
      %{
        "role" => "Senior Engineer",
        "company" => "Acme Corp",
        "accomplishments" => ["Led migration", "Mentored juniors"]
      },
      %{
        "role" => "Junior Engineer",
        "company" => "StartupCo",
        "accomplishments" => ["Built API"]
      }
    ],
    "education" => [
      %{"institution" => "State University", "degree" => "B.S.", "field" => "CS"}
    ],
    "skills" => [
      %{"category" => "Languages", "skills" => ["Elixir", "JavaScript"]}
    ],
    "certifications" => [],
    "projects" => [],
    "publications" => [],
    "volunteer_work" => [],
    "contact_info" => %{"name" => "Test User"}
  }

  describe "replace" do
    test "replaces a top-level scalar" do
      ops = [%{"op" => "replace", "section" => "summary", "value" => "New summary."}]
      result = Patch.apply(@base_data, ops)
      assert result["summary"] == "New summary."
    end

    test "skips replace on unknown section" do
      ops = [%{"op" => "replace", "section" => "bogus", "value" => "nope"}]
      result = Patch.apply(@base_data, ops)
      assert result == @base_data
    end
  end

  describe "replace_item with field" do
    test "replaces a single field within an array item" do
      ops = [
        %{
          "op" => "replace_item",
          "section" => "work_experience",
          "index" => 0,
          "field" => "role",
          "value" => "Staff Engineer"
        }
      ]

      result = Patch.apply(@base_data, ops)
      assert hd(result["work_experience"])["role"] == "Staff Engineer"
      assert hd(result["work_experience"])["company"] == "Acme Corp"
    end

    test "skips out-of-bounds index" do
      ops = [
        %{
          "op" => "replace_item",
          "section" => "work_experience",
          "index" => 99,
          "field" => "role",
          "value" => "Nope"
        }
      ]

      result = Patch.apply(@base_data, ops)
      assert result == @base_data
    end
  end

  describe "replace_item with map value" do
    test "replaces an entire array item" do
      new_item = %{"role" => "CTO", "company" => "NewCo", "accomplishments" => []}

      ops = [
        %{
          "op" => "replace_item",
          "section" => "work_experience",
          "index" => 1,
          "value" => new_item
        }
      ]

      result = Patch.apply(@base_data, ops)
      assert Enum.at(result["work_experience"], 1) == new_item
      assert hd(result["work_experience"])["company"] == "Acme Corp"
    end
  end

  describe "replace_section" do
    test "replaces an entire array section" do
      new_skills = [%{"category" => "Cloud", "skills" => ["AWS", "GCP"]}]

      ops = [
        %{"op" => "replace_section", "section" => "skills", "value" => new_skills}
      ]

      result = Patch.apply(@base_data, ops)
      assert result["skills"] == new_skills
    end

    test "skips when value is not a list" do
      ops = [
        %{"op" => "replace_section", "section" => "skills", "value" => "not a list"}
      ]

      result = Patch.apply(@base_data, ops)
      assert result == @base_data
    end
  end

  describe "add_item" do
    test "appends an item to an array section" do
      new_cert = %{"name" => "AWS SAA", "issuer" => "Amazon", "date" => %{"year" => 2024}}

      ops = [%{"op" => "add_item", "section" => "certifications", "value" => new_cert}]
      result = Patch.apply(@base_data, ops)
      assert length(result["certifications"]) == 1
      assert hd(result["certifications"])["name"] == "AWS SAA"
    end

    test "appends to existing items" do
      new_job = %{"role" => "Intern", "company" => "BigCo", "accomplishments" => []}

      ops = [%{"op" => "add_item", "section" => "work_experience", "value" => new_job}]
      result = Patch.apply(@base_data, ops)
      assert length(result["work_experience"]) == 3
      assert List.last(result["work_experience"])["role"] == "Intern"
    end
  end

  describe "remove_item" do
    test "removes an item from an array section" do
      ops = [%{"op" => "remove_item", "section" => "work_experience", "index" => 1}]
      result = Patch.apply(@base_data, ops)
      assert length(result["work_experience"]) == 1
      assert hd(result["work_experience"])["company"] == "Acme Corp"
    end

    test "skips out-of-bounds index" do
      ops = [%{"op" => "remove_item", "section" => "work_experience", "index" => 5}]
      result = Patch.apply(@base_data, ops)
      assert result == @base_data
    end
  end

  describe "empty and invalid ops" do
    test "empty operations list returns data unchanged" do
      assert Patch.apply(@base_data, []) == @base_data
    end

    test "unknown op type is skipped" do
      ops = [%{"op" => "teleport", "section" => "summary"}]
      result = Patch.apply(@base_data, ops)
      assert result == @base_data
    end
  end

  describe "sequential ops on same array" do
    test "remove then add on same section" do
      ops = [
        %{"op" => "remove_item", "section" => "work_experience", "index" => 0},
        %{
          "op" => "add_item",
          "section" => "work_experience",
          "value" => %{"role" => "VP", "company" => "NewCo", "accomplishments" => []}
        }
      ]

      result = Patch.apply(@base_data, ops)
      assert length(result["work_experience"]) == 2
      assert hd(result["work_experience"])["company"] == "StartupCo"
      assert List.last(result["work_experience"])["role"] == "VP"
    end

    test "multiple replace_item ops on same section" do
      ops = [
        %{
          "op" => "replace_item",
          "section" => "work_experience",
          "index" => 0,
          "field" => "role",
          "value" => "Principal Engineer"
        },
        %{
          "op" => "replace_item",
          "section" => "work_experience",
          "index" => 1,
          "field" => "company",
          "value" => "MegaCorp"
        }
      ]

      result = Patch.apply(@base_data, ops)
      assert hd(result["work_experience"])["role"] == "Principal Engineer"
      assert Enum.at(result["work_experience"], 1)["company"] == "MegaCorp"
    end
  end
end

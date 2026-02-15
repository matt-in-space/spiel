defmodule ResumeWeb.ResumePDFControllerTest do
  use ResumeWeb.ConnCase, async: true

  import Resume.AccountsFixtures

  alias Resume.Resumes

  setup :register_and_log_in_user

  @sample_data %{
    "summary" => "A great engineer.",
    "contact_info" => %{"name" => "Jane Doe", "email" => "jane@example.com"},
    "work_experience" => [
      %{
        "role" => "Developer",
        "company" => "Acme",
        "current" => true,
        "start_date" => %{"year" => 2020, "month" => 1},
        "accomplishments" => ["Built things"]
      }
    ],
    "education" => [],
    "skills" => [%{"category" => "Languages", "skills" => ["Elixir", "Rust"]}],
    "certifications" => [],
    "projects" => [],
    "publications" => [],
    "volunteer_work" => []
  }

  defp create_resume(%{user: user}) do
    {:ok, resume} =
      Resumes.create_resume(%{
        title: "Test Resume",
        user_id: user.id
      })

    {:ok, _version} = Resumes.create_version(resume, "generation", @sample_data)

    %{resume: resume}
  end

  describe "GET /resumes/:id/pdf" do
    setup [:create_resume]

    test "returns a PDF download", %{conn: conn, resume: resume} do
      conn = get(conn, ~p"/resumes/#{resume}/pdf")

      assert response_content_type(conn, :pdf) =~ "application/pdf"

      assert get_resp_header(conn, "content-disposition") == [
               ~s(attachment; filename="Jane_Doe - Test_Resume Resume.pdf")
             ]

      assert response(conn, 200) == "%PDF-1.4 mock"
    end

    test "redirects unauthenticated users", %{resume: resume} do
      conn = build_conn()
      conn = get(conn, ~p"/resumes/#{resume}/pdf")
      assert redirected_to(conn) == ~p"/users/log-in"
    end

    test "404s for another user's resume", %{conn: conn} do
      other_user = user_fixture()

      {:ok, other_resume} =
        Resumes.create_resume(%{
          title: "Other Resume",
          user_id: other_user.id
        })

      {:ok, _version} =
        Resumes.create_version(other_resume, "generation", %{
          "contact_info" => %{"name" => "Other"},
          "work_experience" => [],
          "education" => [],
          "skills" => [],
          "certifications" => [],
          "projects" => [],
          "publications" => [],
          "volunteer_work" => []
        })

      assert_raise Ecto.NoResultsError, fn ->
        get(conn, ~p"/resumes/#{other_resume}/pdf")
      end
    end
  end
end

defmodule Resume.Repo.Migrations.MigrateWebsitesToList do
  use Ecto.Migration

  def up do
    # Transform users.default_resume_data: collect website/linkedin/github into websites list
    execute("""
    UPDATE users
    SET default_resume_data = (
      SELECT jsonb_set(
        (default_resume_data - 'website' - 'linkedin' - 'github'),
        '{websites}',
        coalesce(
          (
            SELECT jsonb_agg(entry)
            FROM (
              SELECT jsonb_build_object('type', 'website', 'url', default_resume_data->>'website') AS entry
              WHERE default_resume_data->>'website' IS NOT NULL AND default_resume_data->>'website' != ''
              UNION ALL
              SELECT jsonb_build_object('type', 'linkedin', 'url', default_resume_data->>'linkedin')
              WHERE default_resume_data->>'linkedin' IS NOT NULL AND default_resume_data->>'linkedin' != ''
              UNION ALL
              SELECT jsonb_build_object('type', 'github', 'url', default_resume_data->>'github')
              WHERE default_resume_data->>'github' IS NOT NULL AND default_resume_data->>'github' != ''
            ) sub
          ),
          '[]'::jsonb
        )
      )
    )
    WHERE default_resume_data IS NOT NULL
    """)

    # Transform resume_versions.data: collect contact_info.website/linkedin/github into websites list
    execute("""
    UPDATE resume_versions
    SET data = jsonb_set(
      data,
      '{contact_info}',
      (
        SELECT jsonb_set(
          (ci - 'website' - 'linkedin' - 'github'),
          '{websites}',
          coalesce(
            (
              SELECT jsonb_agg(entry)
              FROM (
                SELECT jsonb_build_object('type', 'website', 'url', ci->>'website') AS entry
                WHERE ci->>'website' IS NOT NULL AND ci->>'website' != ''
                UNION ALL
                SELECT jsonb_build_object('type', 'linkedin', 'url', ci->>'linkedin')
                WHERE ci->>'linkedin' IS NOT NULL AND ci->>'linkedin' != ''
                UNION ALL
                SELECT jsonb_build_object('type', 'github', 'url', ci->>'github')
                WHERE ci->>'github' IS NOT NULL AND ci->>'github' != ''
              ) sub
            ),
            '[]'::jsonb
          )
        )
        FROM (SELECT data->'contact_info' AS ci) t
      )
    )
    WHERE data->'contact_info' IS NOT NULL
    """)
  end

  def down do
    # Reverse: extract websites list back into individual fields
    execute("""
    UPDATE users
    SET default_resume_data = (
      SELECT (default_resume_data - 'websites')
        || coalesce(
          (SELECT jsonb_build_object('website', url) FROM jsonb_to_recordset(default_resume_data->'websites') AS x(type text, url text) WHERE type = 'website' LIMIT 1),
          '{}'::jsonb
        )
        || coalesce(
          (SELECT jsonb_build_object('linkedin', url) FROM jsonb_to_recordset(default_resume_data->'websites') AS x(type text, url text) WHERE type = 'linkedin' LIMIT 1),
          '{}'::jsonb
        )
        || coalesce(
          (SELECT jsonb_build_object('github', url) FROM jsonb_to_recordset(default_resume_data->'websites') AS x(type text, url text) WHERE type = 'github' LIMIT 1),
          '{}'::jsonb
        )
    )
    WHERE default_resume_data IS NOT NULL AND default_resume_data ? 'websites'
    """)

    execute("""
    UPDATE resume_versions
    SET data = jsonb_set(
      data,
      '{contact_info}',
      (
        SELECT (ci - 'websites')
          || coalesce(
            (SELECT jsonb_build_object('website', url) FROM jsonb_to_recordset(ci->'websites') AS x(type text, url text) WHERE type = 'website' LIMIT 1),
            '{}'::jsonb
          )
          || coalesce(
            (SELECT jsonb_build_object('linkedin', url) FROM jsonb_to_recordset(ci->'websites') AS x(type text, url text) WHERE type = 'linkedin' LIMIT 1),
            '{}'::jsonb
          )
          || coalesce(
            (SELECT jsonb_build_object('github', url) FROM jsonb_to_recordset(ci->'websites') AS x(type text, url text) WHERE type = 'github' LIMIT 1),
            '{}'::jsonb
          )
        FROM (SELECT data->'contact_info' AS ci) t
      )
    )
    WHERE data->'contact_info' IS NOT NULL AND data->'contact_info' ? 'websites'
    """)
  end
end

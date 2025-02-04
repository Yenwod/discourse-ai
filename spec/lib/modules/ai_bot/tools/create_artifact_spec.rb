#frozen_string_literal: true

RSpec.describe DiscourseAi::AiBot::Tools::CreateArtifact do
  fab!(:llm_model)
  let(:llm) { DiscourseAi::Completions::Llm.proxy("custom:#{llm_model.id}") }
  fab!(:post)

  before { SiteSetting.ai_bot_enabled = true }

  describe "#process" do
    it "correctly adds details block on final invoke" do
      responses = [<<~TXT.strip]
          [HTML]
          <div>
            hello
          </div>
          [/HTML]
          [CSS]
          .hello {
            color: red;
          }
          [/CSS]
          [JavaScript]
          console.log("hello");
          console.log("world");
          [/JavaScript]
        TXT

      tool = nil

      DiscourseAi::Completions::Llm.with_prepared_responses(responses) do
        tool =
          described_class.new(
            { html_body: "hello" },
            bot_user: Fabricate(:user),
            llm: llm,
            context: {
              post_id: post.id,
            },
          )

        tool.parameters = { name: "hello", specification: "hello spec" }

        tool.invoke {}
      end

      artifact_id = AiArtifact.order("id desc").limit(1).pluck(:id).first

      expected = <<~MD
        [details="View Source"]
        ### HTML
        ```html
        <div>
          hello
        </div>
        ```

        ### CSS
        ```css
        .hello {
          color: red;
        }
        ```

        ### JavaScript
        ```javascript
        console.log("hello");
        console.log("world");
        ```
        [/details]

        ### Preview
        <div class="ai-artifact" data-ai-artifact-id="#{artifact_id}"></div>
      MD
      expect(tool.custom_raw.strip).to eq(expected.strip)
    end
  end
end

import Component from "@glimmer/component";
import { concat, fn } from "@ember/helper";
import { action } from "@ember/object";
import { LinkTo } from "@ember/routing";
import { inject as service } from "@ember/service";
import DBreadcrumbsItem from "discourse/components/d-breadcrumbs-item";
import icon from "discourse-common/helpers/d-icon";
import i18n from "discourse-common/helpers/i18n";
import I18n from "discourse-i18n";
import AdminPageSubheader from "admin/components/admin-page-subheader";
import AdminSectionLandingItem from "admin/components/admin-section-landing-item";
import AdminSectionLandingWrapper from "admin/components/admin-section-landing-wrapper";
import AiLlmEditor from "./ai-llm-editor";

export default class AiLlmsListEditor extends Component {
  @service adminPluginNavManager;
  @service router;

  @action
  modelDescription(llm) {
    // this is a bit of an odd object, it can be an llm model or a preset model
    // handle both flavors

    // in the case of model
    let key = "";
    if (typeof llm.id === "number") {
      key = `${llm.provider}-${llm.name}`;
    } else {
      // case of preset
      key = llm.id.replace(/\./g, "-");
    }

    key = `discourse_ai.llms.model_description.${key}`;
    if (I18n.lookup(key, { ignoreMissing: true })) {
      return I18n.t(key);
    }
    return "";
  }

  sanitizedTranslationKey(id) {
    return id.replace(/\./g, "-");
  }

  get hasLlmElements() {
    return this.args.llms.length !== 0;
  }

  get preconfiguredTitle() {
    if (this.hasLlmElements) {
      return "discourse_ai.llms.preconfigured.title";
    } else {
      return "discourse_ai.llms.preconfigured.title_no_llms";
    }
  }

  get preConfiguredLlms() {
    const options = [
      {
        id: "none",
        name: I18n.t("discourse_ai.llms.preconfigured.fake"),
        provider: "fake",
      },
    ];

    const llmsContent = this.args.llms.content.map((llm) => ({
      provider: llm.provider,
      name: llm.name,
    }));

    this.args.llms.resultSetMeta.presets.forEach((llm) => {
      if (llm.models) {
        llm.models.forEach((model) => {
          const id = `${llm.id}-${model.name}`;
          const isConfigured = llmsContent.some(
            (content) =>
              content.provider === llm.provider && content.name === model.name
          );

          if (!isConfigured) {
            options.push({
              id,
              name: model.display_name,
              provider: llm.provider,
            });
          }
        });
      }
    });

    return options;
  }

  @action
  transitionToLlmEditor(llmTemplate) {
    this.router.transitionTo("adminPlugins.show.discourse-ai-llms.new", {
      queryParams: { llmTemplate },
    });
  }

  localizeUsage(usage) {
    if (usage.type === "ai_persona") {
      return I18n.t("discourse_ai.llms.usage.ai_persona", {
        persona: usage.name,
      });
    } else {
      return I18n.t("discourse_ai.llms.usage." + usage.type);
    }
  }

  <template>
    <DBreadcrumbsItem
      @path="/admin/plugins/{{this.adminPluginNavManager.currentPlugin.name}}/ai-llms"
      @label={{i18n "discourse_ai.llms.short_title"}}
    />
    <section class="ai-llm-list-editor admin-detail">
      {{#if @currentLlm}}
        <AiLlmEditor
          @model={{@currentLlm}}
          @llms={{@llms}}
          @llmTemplate={{@llmTemplate}}
        />
      {{else}}
        {{#if this.hasLlmElements}}
          <section class="ai-llms-list-editor__configured">
            <AdminPageSubheader
              @titleLabel="discourse_ai.llms.configured.title"
            />
            <table>
              <thead>
                <tr>
                  <th>{{i18n "discourse_ai.llms.display_name"}}</th>
                  <th>{{i18n "discourse_ai.llms.provider"}}</th>
                  <th></th>
                </tr>
              </thead>
              <tbody>
                {{#each @llms as |llm|}}
                  <tr data-persona-id={{llm.id}} class="ai-llm-list__row">
                    <td class="column-name">
                      <h3>{{llm.display_name}}</h3>
                      <p>
                        {{this.modelDescription llm}}
                      </p>
                      {{#if llm.used_by}}
                        <ul class="ai-llm-list-editor__usages">
                          {{#each llm.used_by as |usage|}}
                            <li>{{this.localizeUsage usage}}</li>
                          {{/each}}
                        </ul>
                      {{/if}}
                    </td>
                    <td>
                      {{i18n
                        (concat "discourse_ai.llms.providers." llm.provider)
                      }}
                    </td>
                    <td class="column-edit">
                      <LinkTo
                        @route="adminPlugins.show.discourse-ai-llms.show"
                        class="btn btn-default"
                        @model={{llm.id}}
                      >
                        {{icon "wrench"}}
                        <div class="d-button-label">
                          {{i18n "discourse_ai.llms.edit"}}
                        </div>
                      </LinkTo>
                    </td>
                  </tr>
                {{/each}}
              </tbody>
            </table>
          </section>
        {{/if}}
        <section class="ai-llms-list-editor__templates">
          <AdminPageSubheader @titleLabel={{this.preconfiguredTitle}} />

          <AdminSectionLandingWrapper
            class="ai-llms-list-editor__templates-list"
          >
            {{#each this.preConfiguredLlms as |llm|}}
              <AdminSectionLandingItem
                @titleLabelTranslated={{llm.name}}
                @descriptionLabelTranslated={{this.modelDescription llm}}
                @taglineLabel={{concat
                  "discourse_ai.llms.providers."
                  llm.provider
                }}
                data-llm-id={{llm.id}}
                class="ai-llms-list-editor__templates-list-item"
              >
                <:buttons as |buttons|>
                  <buttons.Default
                    @action={{fn this.transitionToLlmEditor llm.id}}
                    @icon="gear"
                    @label="discourse_ai.llms.preconfigured.button"
                  />
                </:buttons>
              </AdminSectionLandingItem>
            {{/each}}
          </AdminSectionLandingWrapper>
        </section>
      {{/if}}
    </section>
  </template>
}

# frozen_string_literal: true

# Helper para buscar tours pendientes de visualizacion
module AbrahamHelper
  include FlipperHelper

  def abraham_tour
    action = action_name
    # Caso de reporte personalizado con DRY code
    if Report::CustomReportTemplatesController::REPORT_TEMPLATES_ACTIONS.include?(action_name.to_sym) && controller_path == "report/custom_report_templates"
      action = "new"
    end
    # Do we have tours for this controller/action in the user's locale?
    tours = Rails.configuration.abraham.tours["#{controller_path}/#{action}/#{I18n.locale}"]
    # Otherwise, default to the default locale
    tours ||= Rails.configuration.abraham.tours["#{controller_path}/#{action}/#{I18n.default_locale}"]

    if tours
      # Have any automatic tours been completed already?
      conditions = {
        creator_id: current_user.id,
        controller_name: controller_path,
      }

      # Si el controlador no es "report/custom_report_templates", incluye el filtro de `action_name`
      conditions[:action_name] = action unless controller_path == "report/custom_report_templates"

      completed = AbrahamHistory.where(conditions)

      tour_keys_completed = completed.map(&:tour_name)
      tour_locale_key = tours.keys.first
      tour_keys = tours[tour_locale_key].keys

      tour_html = ''

      tour_keys.each do |key|
        selected_tour = tours[tour_locale_key][key]
        flipper_key = selected_tour["flipper_key"]
        flipper_activation = selected_tour["flipper_activation"]

        next unless should_add_tour(flipper_key, flipper_activation) && !tour_keys_completed.include?(key)
        tour_html += render(partial: "application/abraham",
                            locals: { tour_name: key,
                                      tour_completed: tour_keys_completed.include?(key),
                                      trigger: selected_tour["trigger"],
                                      display: selected_tour["display"],
                                      enable_amplitude: selected_tour["enable_amplitude"],
                                      steps: selected_tour["steps"],
                                      action: action,
                                      custom_function_on_cancel: selected_tour["custom_function_on_cancel"], },)
      end

      tour_html.html_safe
    end
  end

  def abraham_cookie_prefix
    "abraham-#{fetch_application_name.to_s.underscore}-#{current_user.id}-#{controller_path}-#{action_name}"
  end

  def fetch_application_name
    if Module.method_defined?(:module_parent)
      Rails.application.class.module_parent
    else
      Rails.application.class.parent
    end
  end

  def abraham_domain
    request.host
  end
end

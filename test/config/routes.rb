# frozen_string_literal: true

Dummy::Application.routes.draw do
  root to: "integration_examples#index"
  get :deprecated, to: "integration_examples#deprecated"
  get :component, to: "integration_examples#component"
  get :content_areas, to: "integration_examples#content_areas"
  get :partial, to: "integration_examples#partial"
  get :layout, to: "integration_examples#layout"
  get :content, to: "integration_examples#content"
  get :variants, to: "integration_examples#variants"
  get :cached, to: "integration_examples#cached"
  get :render_check, to: "integration_examples#render_check"
end

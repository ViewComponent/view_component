# frozen_string_literal: true

Dummy::Application.routes.draw do
  root to: "integration_examples#index"
  get :content_areas, to: "integration_examples#content_areas"
  get :partial, to: "integration_examples#partial"
  get :content, to: "integration_examples#content"
  get :variants, to: "integration_examples#variants"
  get :products, to: "integration_examples#products"
  get :cached, to: "integration_examples#cached"
  get :render_check, to: "integration_examples#render_check"
  get :controller_inline, to: "integration_examples#controller_inline"
  get :controller_inline_baseline, to: "integration_examples#controller_inline_baseline"
  get :controller_to_string, to: "integration_examples#controller_to_string"
  resources :posts
end

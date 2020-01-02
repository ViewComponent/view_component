# frozen_string_literal: true

Dummy::Application.routes.draw do
  root to: "application#index"
  get :deprecated, to: "application#deprecated"
  get :component, to: "application#component"
  get :content_areas, to: "application#content_areas"
  get :partial, to: "application#partial"
  get :content, to: "application#content"
  get :variants, to: "application#variants"
  get :cached, to: "application#cached"
end

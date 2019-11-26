# frozen_string_literal: true

Dummy::Application.routes.draw do
  root to: "application#index"
  get :component, to: "application#component"
  get :partial, to: "application#partial"
  get :content, to: "application#content"
  get :variants, to: "application#variants"
  get :cached, to: "application#cached"
end

# decor/app/models/component_condition.rb
# version 1.0
# New model for the component_conditions table introduced in Session 7
# (February 25, 2026).
#
# The value column is named "condition" (not "name") to distinguish it from
# the computer_conditions lookup pattern — this is an intentional design choice.
#
# Deletion behaviour: restrict_with_error — a component_condition record cannot
# be deleted while any component still references it. The user must reassign
# or clear the condition on all components first. This matches the stricter
# pattern used elsewhere in the project and prevents accidental data loss.

class ComponentCondition < ApplicationRecord
  has_many :components, dependent: :restrict_with_error
end

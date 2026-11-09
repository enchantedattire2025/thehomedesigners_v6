/*
  # Remove Problematic Quote Status Trigger

  This migration removes a trigger and function that reference a non-existent field.

  ## Problem
  The `update_quote_status_on_send()` function tries to access a `sent_at` field
  that doesn't exist in the `designer_quotes` table, causing errors when the
  trigger fires.

  ## Changes
  - Drop the trigger `update_quote_status_trigger` on the `designer_quotes` table
  - Drop the function `update_quote_status_on_send()`

  Both are dropped with IF EXISTS clauses to ensure safe execution.
*/

DROP TRIGGER IF EXISTS update_quote_status_trigger ON designer_quotes;

DROP FUNCTION IF EXISTS update_quote_status_on_send();

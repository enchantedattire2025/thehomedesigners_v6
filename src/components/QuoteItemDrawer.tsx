
import React, { useEffect, useState } from 'react';
import { Image as ImageIcon, X } from 'lucide-react';
import type { Material, QuoteItem } from '../pages/DesignerQuoteGenerator';
import { calculateItem, itemRate } from '../utils/quoteItemCalculation';

type DrawerItem = QuoteItem;

interface QuoteItemDrawerProps {
  isOpen: boolean;
  item: DrawerItem | null;
  materials: Material[];
  roomName: string;
  formatCurrency: (amount: number) => string;
  onClose: () => void;
  onSave: (item: DrawerItem) => void;
  onUpload: (file: File) => Promise<string>;
}

const MAX_UNIT_PRICE = 10_000_000;
const MAX_QUANTITY = 1_000_000;
const MAX_UNITS = 100_000;
const MAX_DIMENSION = 10_000;
const MAX_AMOUNT = 1_000_000_000_000;

const baseItem = (section: string): QuoteItem => ({
  item_type: 'material',
  name: '',
  description: '',
  number_of_units: 1,
  quantity: 1,
  unit: 'sq.ft',
  unit_price: 0,
  discount_percent: 0,
  amount: 0,
  section,
  pricing_mode: 'modular',
  width_unit: 'feet',
  height_unit: 'feet',
  depth_unit: 'feet',
});

const QuoteItemDrawer = ({
  isOpen,
  item,
  materials,
  roomName,
  formatCurrency,
  onClose,
  onSave,
  onUpload,
}: QuoteItemDrawerProps) => {
  const [draft, setDraft] = useState<DrawerItem>(
    item ? { ...item, pricing_mode: 'modular' } : baseItem(roomName)
  );
  const [uploading, setUploading] = useState(false);
  const [validationError, setValidationError] = useState('');

  useEffect(() => {
    if (isOpen) {
      setDraft(item ? { ...item, pricing_mode: 'modular' } : baseItem(roomName));
      setValidationError('');
    }
  }, [isOpen, item, roomName]);

  if (!isOpen) return null;

  const update = <K extends keyof DrawerItem>(
    field: K,
    value: DrawerItem[K]
  ) => {
    setDraft(previous => ({
      ...previous,
      [field]: value,
    }));
  };

  const isModular = draft.pricing_mode === 'modular';

  const discount = draft.discount_percent ?? 0;

  const rate = itemRate(draft);

  const width = draft.width ?? 0;
  const height = draft.height ?? 0;
  const units = draft.number_of_units;
  const quantity = draft.quantity;

  const rawAmount = calculateItem(draft).amount;

  const amount = Number.isFinite(rawAmount)
    ? Math.round((rawAmount + Number.EPSILON) * 100) / 100
    : 0;

  const isAmountValid =
    Number.isFinite(rawAmount) &&
    rawAmount >= 0 &&
    rawAmount <= MAX_AMOUNT;

  const selectMaterial = (id: string) => {
    const material = materials.find(entry => entry.id === id);
    if (!material) return;

    const price =
      material.is_discounted && material.discount_price !== null
        ? material.discount_price
        : material.base_price;

    if (
      !Number.isFinite(price) ||
      price < 0 ||
      price > MAX_UNIT_PRICE
    ) {
      setValidationError('The selected material has an invalid price.');
      return;
    }

    setValidationError('');

    setDraft(previous => ({
      ...previous,
      material_id: material.id,
      name: material.name,
      description: material.description || '',
      unit: material.unit,
      ...(isModular ? { per_sqft_rate: price } : { unit_price: price }),
    }));
  };

  const handleFile = async (
    event: React.ChangeEvent<HTMLInputElement>
  ) => {
    const file = event.target.files?.[0];
    if (!file) return;

    setUploading(true);

    try {
      const imageUrl = await onUpload(file);
      update('image_url', imageUrl);
    } catch {
      setValidationError('Image upload failed. Please try again.');
    } finally {
      setUploading(false);
      event.target.value = '';
    }
  };

  const updateNumeric = (
    field:
      | 'number_of_units'
      | 'quantity'
      | 'unit_price'
      | 'discount_percent'
      | 'width'
      | 'height'
      | 'depth'
      | 'per_sqft_rate',
    rawValue: string,
    max: number,
    min: number,
    integer = false
  ) => {
    if (rawValue === '') {
      setValidationError('');

      if (field === 'number_of_units') {
        update('number_of_units', 0);
      } else if (field === 'quantity') {
        update('quantity', 0);
      } else if (field === 'unit_price') {
        update('unit_price', 0);
      } else if (field === 'per_sqft_rate') {
        update('per_sqft_rate', 0);
      } else if (field === 'discount_percent') {
        update('discount_percent', 0);
      } else {
        update(field, 0);
      }

      return;
    }

    const value = Number(rawValue);

    if (
      !Number.isFinite(value) ||
      value < min ||
      value > max ||
      (integer && !Number.isInteger(value))
    ) {
      setValidationError(
        `Enter a valid value between ${min} and ${max}.`
      );
      return;
    }

    setValidationError('');

    if (field === 'number_of_units') {
      update('number_of_units', value);
    } else if (field === 'quantity') {
      update('quantity', value);
    } else if (field === 'unit_price') {
      update('unit_price', value);
    } else if (field === 'discount_percent') {
      update('discount_percent', value);
    } else if (field === 'width') {
      update('width', value);
    } else if (field === 'height') {
      update('height', value);
    } else if (field === 'depth') {
      update('depth', value);
    } else if (field === 'per_sqft_rate') {
      update('per_sqft_rate', value);
    }
  };

  const save = () => {
    const valid =
      draft.name.trim().length > 0 &&
      Number.isFinite(units) &&
      units > 0 &&
      units <= MAX_UNITS &&
      Number.isInteger(units) &&
      Number.isFinite(discount) &&
      discount >= 0 &&
      discount <= 100 &&
      Number.isFinite(rate) &&
      rate > 0 &&
      rate <= MAX_UNIT_PRICE &&
      (
        isModular ||
        (
          Number.isFinite(quantity) &&
          quantity > 0 &&
          quantity <= MAX_QUANTITY
        )
      ) &&
      (
        !isModular ||
        (
          Number.isFinite(width) &&
          Number.isFinite(height) &&
          width > 0 &&
          height > 0 &&
          width <= MAX_DIMENSION &&
          height <= MAX_DIMENSION
        )
      ) &&
      isAmountValid;

    if (!valid) {
      setValidationError(
        'Please check the item name, units, quantity, dimensions, price, discount and calculated amount.'
      );
      return;
    }

    setValidationError('');

    onSave({ ...draft, amount });
  };

  const numberInputClass =
    'mt-1 w-full rounded-lg border border-gray-300 px-3 py-2 font-normal focus:ring-2 focus:ring-primary-500 focus:border-transparent';

  const blockInvalidKeys = (
    event: React.KeyboardEvent<HTMLInputElement>
  ) => {
    if (['-', '+', 'e', 'E'].includes(event.key)) {
      event.preventDefault();
    }
  };

  return (
    <div
      className="fixed inset-0 z-50 flex justify-end bg-black/40"
      role="dialog"
      aria-modal="true"
    >
      <button
        type="button"
        className="absolute inset-0 cursor-default"
        onClick={onClose}
        aria-label="Close drawer"
      />

      <aside className="relative flex h-full w-full max-w-xl flex-col bg-white shadow-2xl">
        <div className="flex items-center justify-between border-b border-gray-200 px-5 py-4">
          <div>
            <h2 className="text-xl font-semibold text-secondary-800">
              {item ? 'Edit Item' : 'Add Item'}
            </h2>
            <p className="text-xs text-gray-500">{roomName}</p>
          </div>

          <button
            type="button"
            onClick={onClose}
            className="rounded-lg p-2 text-gray-500 hover:bg-gray-100"
            aria-label="Close"
          >
            <X className="h-5 w-5" />
          </button>
        </div>

        <div className="flex-1 space-y-4 overflow-y-auto px-5 py-5">
          <div className="grid grid-cols-2 gap-3">
            <label className="text-sm font-medium text-gray-700">
              Item type
              <select
                value={draft.item_type}
                onChange={event =>
                  update(
                    'item_type',
                    event.target.value as QuoteItem['item_type']
                  )
                }
                className={numberInputClass}
              >
                <option value="material">Material</option>
                <option value="labor">Labor</option>
                <option value="service">Service</option>
                <option value="component">Component</option>
                <option value="other">Other</option>
              </select>
            </label>

            <label className="text-sm font-medium text-gray-700">
              Pricing mode
              <select
                value={isModular ? 'modular' : 'standard'}
                onChange={event =>
                  update(
                    'pricing_mode',
                    event.target.value === 'modular' ? 'modular' : 'standard'
                  )
                }
                className={numberInputClass}
              >
                <option value="modular">Dimensions × rate</option>
                <option value="standard">Quantity × rate</option>
              </select>
            </label>
          </div>

          {draft.item_type === 'material' && (
            <label className="block text-sm font-medium text-gray-700">
              Material
              <select
                value={draft.material_id || ''}
                onChange={event => selectMaterial(event.target.value)}
                className={numberInputClass}
              >
                <option value="">Select from catalog</option>
                {materials.map(material => (
                  <option key={material.id} value={material.id}>
                    {material.name} ·{' '}
                    {formatCurrency(
                      material.is_discounted &&
                      material.discount_price !== null
                        ? material.discount_price
                        : material.base_price
                    )}
                    /{material.unit}
                  </option>
                ))}
              </select>
            </label>
          )}

          <label className="block text-sm font-medium text-gray-700">
            Item name
            <input
              value={draft.name}
              onChange={event => update('name', event.target.value)}
              placeholder="e.g. TV Unit"
              className={numberInputClass}
            />
          </label>

          <label className="block text-sm font-medium text-gray-700">
            Description
            <textarea
              value={draft.description}
              onChange={event => update('description', event.target.value)}
              rows={2}
              className={numberInputClass}
            />
          </label>

          <div>
            <p className="mb-2 text-sm font-medium text-gray-700">
              Item image
            </p>

            <div className="flex items-center gap-3">
              {draft.image_url ? (
                <img
                  src={draft.image_url}
                  alt="Item"
                  className="h-16 w-16 rounded-lg border object-cover"
                />
              ) : (
                <div className="flex h-16 w-16 items-center justify-center rounded-lg bg-gray-100 text-gray-400">
                  <ImageIcon className="h-5 w-5" />
                </div>
              )}

              <label className="cursor-pointer rounded-lg border border-primary-300 px-3 py-2 text-xs font-semibold text-primary-700 hover:bg-primary-50">
                {uploading
                  ? 'Processing…'
                  : draft.image_url
                    ? 'Change image'
                    : 'Upload image'}

                <input
                  type="file"
                  accept="image/*"
                  onChange={handleFile}
                  disabled={uploading}
                  className="hidden"
                />
              </label>

              {draft.image_url && (
                <button
                  type="button"
                  onClick={() => update('image_url', null)}
                  className="text-xs font-semibold text-red-600"
                >
                  Remove
                </button>
              )}
            </div>
          </div>

          {isModular ? (
            <div className="grid grid-cols-3 gap-3">
              {(['width', 'height', 'depth'] as const).map(field => (
                <label
                  key={field}
                  className="text-sm font-medium capitalize text-gray-700"
                >
                  {field}
                  <input
                    type="number"
                    min="0.01"
                    max={MAX_DIMENSION}
                    step="0.01"
                    value={draft[field] ?? ''}
                    onKeyDown={blockInvalidKeys}
                    onChange={event =>
                      updateNumeric(
                        field,
                        event.target.value,
                        MAX_DIMENSION,
                        0.01
                      )
                    }
                    className={numberInputClass}
                  />
                </label>
              ))}
            </div>
          ) : (
            <div className="grid grid-cols-3 gap-3">
              <label className="text-sm font-medium text-gray-700">
                Units
                <input
                  type="number"
                  min="1"
                  max={MAX_UNITS}
                  step="1"
                  value={draft.number_of_units}
                  onKeyDown={blockInvalidKeys}
                  onChange={event =>
                    updateNumeric(
                      'number_of_units',
                      event.target.value,
                      MAX_UNITS,
                      1,
                      true
                    )
                  }
                  className={numberInputClass}
                />
              </label>

              <label className="text-sm font-medium text-gray-700">
                Quantity
                <input
                  type="number"
                  min="0.01"
                  max={MAX_QUANTITY}
                  step="0.01"
                  value={draft.quantity}
                  onKeyDown={blockInvalidKeys}
                  onChange={event =>
                    updateNumeric(
                      'quantity',
                      event.target.value,
                      MAX_QUANTITY,
                      0.01
                    )
                  }
                  className={numberInputClass}
                />
              </label>

              <label className="text-sm font-medium text-gray-700">
                Unit
                <input
                  value={draft.unit}
                  onChange={event => update('unit', event.target.value)}
                  className={numberInputClass}
                />
              </label>
            </div>
          )}

          <div className="grid grid-cols-2 gap-3">
            <label className="text-sm font-medium text-gray-700">
              {isModular ? 'Rate per sq.ft' : 'Unit price'}
              <input
                type="number"
                min="0.01"
                max={MAX_UNIT_PRICE}
                step="0.01"
                value={rate}
                onKeyDown={blockInvalidKeys}
                onChange={event =>
                  updateNumeric(
                    isModular ? 'per_sqft_rate' : 'unit_price',
                    event.target.value,
                    MAX_UNIT_PRICE,
                    0.01
                  )
                }
                className={numberInputClass}
              />
            </label>

            <label className="text-sm font-medium text-gray-700">
              Discount %
              <input
                type="number"
                min="0"
                max="100"
                step="0.01"
                value={draft.discount_percent}
                onKeyDown={blockInvalidKeys}
                onChange={event =>
                  updateNumeric(
                    'discount_percent',
                    event.target.value,
                    100,
                    0
                  )
                }
                className={numberInputClass}
              />
            </label>
          </div>

          {validationError && (
            <p
              role="alert"
              className="rounded-lg bg-red-50 p-3 text-sm text-red-700"
            >
              {validationError}
            </p>
          )}

          <div className="rounded-xl bg-primary-50 p-4">
            <p className="text-xs font-medium uppercase tracking-wide text-primary-700">
              Calculated amount
            </p>
            <p className="mt-1 break-words text-2xl font-bold text-primary-800">
              {isAmountValid
                ? formatCurrency(amount)
                : 'Invalid amount'}
            </p>
          </div>
        </div>

        <div className="flex gap-3 border-t border-gray-200 p-5">
          <button
            type="button"
            onClick={onClose}
            className="flex-1 rounded-xl border border-gray-300 px-4 py-3 font-semibold text-gray-700 hover:bg-gray-50"
          >
            Cancel
          </button>

          <button
            type="button"
            onClick={save}
            disabled={
              !draft.name.trim() ||
              !isAmountValid ||
              uploading
            }
            className="flex-1 rounded-xl bg-primary-600 px-4 py-3 font-semibold text-white hover:bg-primary-700 disabled:cursor-not-allowed disabled:opacity-50"
          >
            Save Item
          </button>
        </div>
      </aside>
    </div>
  );
};

export default QuoteItemDrawer;

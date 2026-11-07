import type { QuoteItem } from '../pages/DesignerQuoteGenerator';

const toFeet = (value: number, unit: 'mm' | 'inch' | 'feet' = 'feet') => unit === 'mm' ? value / 304.8 : unit === 'inch' ? value / 12 : value;

const modularArea = (item: QuoteItem) => {
  const width = toFeet(item.width || 0, item.width_unit);
  const height = toFeet(item.height || 0, item.height_unit);
  const depth = item.depth && item.depth > 0 ? toFeet(item.depth, item.depth_unit) : 1;
  return width > 0 && height > 0 ? width * height * depth : 0;
};

export const itemRate = (item: QuoteItem) =>
  item.pricing_mode === 'modular' ? item.per_sqft_rate ?? 0 : item.unit_price ?? 0;

export const calculateItem = (item: QuoteItem): QuoteItem => {
  const units = item.number_of_units || 1;
  const discountFactor = 1 - (item.discount_percent || 0) / 100;

  if (item.pricing_mode === 'modular') {
    const area = modularArea(item);
    return {
      ...item,
      area_sqft: parseFloat(area.toFixed(2)),
      amount: area * units * itemRate(item) * discountFactor,
    };
  }

  return {
    ...item,
    amount: units * item.quantity * (item.unit_price || 0) * discountFactor,
  };
};

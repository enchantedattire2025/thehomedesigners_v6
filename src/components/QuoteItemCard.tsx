import { Copy, CreditCard as Edit3, Image as ImageIcon, Trash2 } from 'lucide-react';
import type { QuoteItem } from '../pages/DesignerQuoteGenerator';

interface QuoteItemCardProps {
  item: QuoteItem;
  index: number;
  formatCurrency: (amount: number) => string;
  onEdit: () => void;
  onDuplicate: () => void;
  onDelete: () => void;
}

const QuoteItemCard = ({ item, index, formatCurrency, onEdit, onDuplicate, onDelete }: QuoteItemCardProps) => {
  const dimensions = [item.width, item.height, item.depth].filter(value => value && value > 0).join(' × ');
  const measurement = item.pricing_mode === 'modular' ? `${item.area_sqft ?? 0} sq.ft` : `${item.quantity} ${item.unit}`;

  return (
    <article className="rounded-xl border border-gray-200 bg-white p-3 shadow-sm transition hover:border-primary-300 hover:shadow-md">
      <div className="flex items-start gap-3">
        {item.image_url ? (
          <img src={item.image_url} alt="" className="h-14 w-14 flex-shrink-0 rounded-lg border border-gray-200 object-cover" />
        ) : (
          <div className="flex h-14 w-14 flex-shrink-0 items-center justify-center rounded-lg bg-gray-100 text-gray-400">
            <ImageIcon className="h-5 w-5" />
          </div>
        )}
        <div className="min-w-0 flex-1">
          <div className="flex flex-wrap items-center gap-2">
            <span className="text-xs font-semibold text-gray-400">{String(index + 1).padStart(2, '0')}</span>
            <h4 className="truncate font-semibold text-secondary-800">{item.name || 'Untitled item'}</h4>
            <span className="rounded-full bg-primary-50 px-2 py-0.5 text-[11px] font-medium capitalize text-primary-700">{item.item_type}</span>
          </div>
          <p className="mt-1 line-clamp-1 text-xs text-gray-500">{item.description || 'No description added'}</p>
          <div className="mt-2 flex flex-wrap gap-x-4 gap-y-1 text-xs text-gray-600">
            <span><strong className="font-semibold text-gray-800">{item.number_of_units}</strong> units</span>
            <span><strong className="font-semibold text-gray-800">{measurement}</strong></span>
            {dimensions && <span>Size {dimensions}</span>}
          </div>
        </div>
        <div className="flex flex-shrink-0 items-start gap-1">
          <button type="button" onClick={onEdit} className="rounded-lg p-2 text-primary-700 transition hover:bg-primary-50" title="Edit item" aria-label="Edit item"><Edit3 className="h-4 w-4" /></button>
          <button type="button" onClick={onDuplicate} className="rounded-lg p-2 text-gray-600 transition hover:bg-gray-100" title="Duplicate item" aria-label="Duplicate item"><Copy className="h-4 w-4" /></button>
          <button type="button" onClick={onDelete} className="rounded-lg p-2 text-red-600 transition hover:bg-red-50" title="Delete item" aria-label="Delete item"><Trash2 className="h-4 w-4" /></button>
        </div>
      </div>
      <div className="mt-3 flex items-center justify-between border-t border-gray-100 pt-2 text-xs text-gray-500">
        <span>{formatCurrency(item.unit_price)} / {item.pricing_mode === 'modular' ? 'sq.ft' : item.unit}</span>
        {item.discount_percent > 0 && <span className="text-emerald-700">{item.discount_percent}% item discount</span>}
        <strong className="text-sm text-secondary-800">{formatCurrency(item.amount)}</strong>
      </div>
    </article>
  );
};

export default QuoteItemCard;

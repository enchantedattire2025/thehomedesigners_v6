import type { QuoteItem } from '../pages/DesignerQuoteGenerator';
import { bestMaterialMatch } from '../utils/fuzzyMaterialMatch';

export type ScopeLevel = 'essential' | 'standard' | 'complete';
export type PricingMethod = 'per_sqft' | 'per_running_ft' | 'per_unit' | 'lump_sum';
export type KitchenShape = 'L-shaped' | 'Straight' | 'Parallel' | 'U-shaped' | 'Island' | 'Peninsula';

export interface TemplateItem {
  name: string;
  description: string;
  pricingMethod: PricingMethod;
  defaultQuantity: number;
  unit: string;
  width?: number;
  height?: number;
  depth?: number;
  widthUnit?: 'feet' | 'inch' | 'mm';
  heightUnit?: 'feet' | 'inch' | 'mm';
  depthUnit?: 'feet' | 'inch' | 'mm';
  matchKeyword?: string;
  isOptional: boolean;
  scopes: ScopeLevel[];
}

export interface TemplateRoom {
  id: string;
  name: string;
  icon: string;
  defaultIncluded: boolean;
  items: TemplateItem[];
}

export interface HomeTemplate {
  id: string;
  name: string;
  bedrooms: number;
  description: string;
  rooms: TemplateRoom[];
}

export const HOME_TEMPLATES: HomeTemplate[] = [
  {
    id: '1bhk',
    name: '1 BHK',
    bedrooms: 1,
    description: '1 Bedroom, Hall, Kitchen',
    rooms: [
      {
        id: 'living',
        name: 'Living Room',
        icon: 'sofa',
        defaultIncluded: true,
        items: [
          { name: 'TV Unit', description: '', pricingMethod: 'per_sqft', defaultQuantity: 1, unit: 'sq.ft', width: 7, height: 7, depth: 2, widthUnit: 'feet', heightUnit: 'feet', depthUnit: 'feet', matchKeyword: 'TV Unit', isOptional: false, scopes: ['essential', 'standard', 'complete'] },
          { name: 'TV Back Panel', description: '', pricingMethod: 'per_sqft', defaultQuantity: 1, unit: 'sq.ft', width: 7, height: 4, widthUnit: 'feet', heightUnit: 'feet', matchKeyword: 'TV Back Panel', isOptional: false, scopes: ['standard', 'complete'] },
          { name: 'Shoe Rack', description: '', pricingMethod: 'per_sqft', defaultQuantity: 1, unit: 'sq.ft', width: 4, height: 7, depth: 1.5, widthUnit: 'feet', heightUnit: 'feet', depthUnit: 'feet', matchKeyword: 'Shoe Rack', isOptional: false, scopes: ['standard', 'complete'] },
          { name: 'False Ceiling', description: 'Living room false ceiling with LED lighting', pricingMethod: 'per_sqft', defaultQuantity: 120, unit: 'sq.ft', matchKeyword: 'False Ceiling', isOptional: true, scopes: ['complete'] },
        ],
      },
      {
        id: 'bedroom1',
        name: 'Bedroom',
        icon: 'bed',
        defaultIncluded: true,
        items: [
          { name: 'Queen Bed', description: 'Queen size bed with storage', pricingMethod: 'per_unit', defaultQuantity: 1, unit: 'unit', matchKeyword: 'Bed', isOptional: false, scopes: ['essential', 'standard', 'complete'] },
          { name: 'Bed Back Panel', description: '', pricingMethod: 'per_sqft', defaultQuantity: 1, unit: 'sq.ft', width: 5, height: 4, widthUnit: 'feet', heightUnit: 'feet', matchKeyword: 'Bed Back Panel', isOptional: false, scopes: ['standard', 'complete'] },
          { name: 'Bedside Tables', description: '2 bedside tables', pricingMethod: 'per_unit', defaultQuantity: 2, unit: 'unit', matchKeyword: 'Bedside Table', isOptional: false, scopes: ['standard', 'complete'] },
          { name: 'Wardrobe', description: 'Material: HDHMR, Finish: Laminate, Hardware: Soft Close, Loft: Yes', pricingMethod: 'per_sqft', defaultQuantity: 1, unit: 'sq.ft', width: 7, height: 7, depth: 2, widthUnit: 'feet', heightUnit: 'feet', depthUnit: 'feet', matchKeyword: 'Wardrobe', isOptional: false, scopes: ['essential', 'standard', 'complete'] },
          { name: 'Loft above Wardrobe', description: '', pricingMethod: 'per_sqft', defaultQuantity: 1, unit: 'sq.ft', width: 7, height: 2, depth: 2, widthUnit: 'feet', heightUnit: 'feet', depthUnit: 'feet', matchKeyword: 'Loft', isOptional: false, scopes: ['standard', 'complete'] },
          { name: 'Dressing Unit', description: '', pricingMethod: 'per_sqft', defaultQuantity: 1, unit: 'sq.ft', width: 4, height: 7, depth: 1.5, widthUnit: 'feet', heightUnit: 'feet', depthUnit: 'feet', matchKeyword: 'Dressing', isOptional: true, scopes: ['standard', 'complete'] },
          { name: 'Study Table', description: '', pricingMethod: 'per_unit', defaultQuantity: 1, unit: 'unit', matchKeyword: 'Study Table', isOptional: true, scopes: ['complete'] },
        ],
      },
      {
        id: 'kitchen',
        name: 'Kitchen',
        icon: 'cooking',
        defaultIncluded: true,
        items: [
          { name: 'Base Cabinets', description: 'Kitchen base cabinets with drawers and sink unit', pricingMethod: 'per_running_ft', defaultQuantity: 12, unit: 'running ft', matchKeyword: 'Kitchen Base', isOptional: false, scopes: ['essential', 'standard', 'complete'] },
          { name: 'Wall Cabinets', description: 'Overhead kitchen cabinets', pricingMethod: 'per_running_ft', defaultQuantity: 10, unit: 'running ft', matchKeyword: 'Kitchen Wall', isOptional: false, scopes: ['essential', 'standard', 'complete'] },
          { name: 'Tall Unit', description: 'Pantry tall unit', pricingMethod: 'per_sqft', defaultQuantity: 1, unit: 'sq.ft', width: 2, height: 7, depth: 2, widthUnit: 'feet', heightUnit: 'feet', depthUnit: 'feet', matchKeyword: 'Tall Unit', isOptional: true, scopes: ['standard', 'complete'] },
          { name: 'Loft', description: 'Kitchen loft', pricingMethod: 'per_running_ft', defaultQuantity: 12, unit: 'running ft', matchKeyword: 'Kitchen Loft', isOptional: true, scopes: ['standard', 'complete'] },
          { name: 'Chimney', description: 'Appliance - supplied by homeowner unless noted', pricingMethod: 'per_unit', defaultQuantity: 1, unit: 'unit', matchKeyword: 'Chimney', isOptional: true, scopes: ['complete'] },
          { name: 'Hob', description: 'Appliance - supplied by homeowner unless noted', pricingMethod: 'per_unit', defaultQuantity: 1, unit: 'unit', matchKeyword: 'Hob', isOptional: true, scopes: ['complete'] },
        ],
      },
      {
        id: 'dining',
        name: 'Dining',
        icon: 'utensils',
        defaultIncluded: false,
        items: [
          { name: 'Crockery Unit', description: '', pricingMethod: 'per_sqft', defaultQuantity: 1, unit: 'sq.ft', width: 5, height: 7, depth: 1.5, widthUnit: 'feet', heightUnit: 'feet', depthUnit: 'feet', matchKeyword: 'Crockery', isOptional: false, scopes: ['standard', 'complete'] },
          { name: 'Dining Back Panel', description: '', pricingMethod: 'per_sqft', defaultQuantity: 1, unit: 'sq.ft', width: 6, height: 4, widthUnit: 'feet', heightUnit: 'feet', matchKeyword: 'Dining Back Panel', isOptional: true, scopes: ['complete'] },
        ],
      },
      {
        id: 'entrance',
        name: 'Entrance / Foyer',
        icon: 'door',
        defaultIncluded: false,
        items: [
          { name: 'Shoe Rack', description: 'Entrance shoe rack with seating', pricingMethod: 'per_sqft', defaultQuantity: 1, unit: 'sq.ft', width: 4, height: 7, depth: 1.5, widthUnit: 'feet', heightUnit: 'feet', depthUnit: 'feet', matchKeyword: 'Shoe Rack', isOptional: false, scopes: ['standard', 'complete'] },
          { name: 'Console Table', description: '', pricingMethod: 'per_unit', defaultQuantity: 1, unit: 'unit', matchKeyword: 'Console', isOptional: true, scopes: ['complete'] },
        ],
      },
      {
        id: 'bathroom',
        name: 'Bathroom',
        icon: 'shower',
        defaultIncluded: false,
        items: [
          { name: 'Vanity Unit', description: 'Bathroom vanity with sink and storage', pricingMethod: 'per_unit', defaultQuantity: 1, unit: 'unit', matchKeyword: 'Vanity', isOptional: false, scopes: ['complete'] },
          { name: 'Mirror Cabinet', description: '', pricingMethod: 'per_unit', defaultQuantity: 1, unit: 'unit', matchKeyword: 'Mirror Cabinet', isOptional: true, scopes: ['complete'] },
        ],
      },
      {
        id: 'electrical',
        name: 'Electrical',
        icon: 'zap',
        defaultIncluded: false,
        items: [
          { name: 'Additional Light Points', description: '', pricingMethod: 'per_unit', defaultQuantity: 10, unit: 'unit', matchKeyword: 'Light Point', isOptional: false, scopes: ['complete'] },
          { name: 'Fan Points', description: '', pricingMethod: 'per_unit', defaultQuantity: 2, unit: 'unit', matchKeyword: 'Fan Point', isOptional: false, scopes: ['complete'] },
          { name: 'AC Points', description: '', pricingMethod: 'per_unit', defaultQuantity: 1, unit: 'unit', matchKeyword: 'AC Point', isOptional: false, scopes: ['complete'] },
          { name: 'LED Strip Lighting', description: '', pricingMethod: 'per_unit', defaultQuantity: 5, unit: 'unit', matchKeyword: 'LED Strip', isOptional: true, scopes: ['complete'] },
        ],
      },
      {
        id: 'painting',
        name: 'Painting / Wall Finishes',
        icon: 'paintbrush',
        defaultIncluded: false,
        items: [
          { name: 'Interior Painting', description: 'Premium emulsion paint for all walls', pricingMethod: 'per_sqft', defaultQuantity: 400, unit: 'sq.ft', matchKeyword: 'Painting', isOptional: false, scopes: ['complete'] },
          { name: 'Wall Panelling', description: 'Decorative wall panel', pricingMethod: 'per_sqft', defaultQuantity: 50, unit: 'sq.ft', matchKeyword: 'Wall Panel', isOptional: true, scopes: ['complete'] },
        ],
      },
    ],
  },

  {
    id: '2bhk',
    name: '2 BHK',
    bedrooms: 2,
    description: '2 Bedrooms, Living, Kitchen, Dining',
    rooms: [
      {
        id: 'living',
        name: 'Living Room',
        icon: 'sofa',
        defaultIncluded: true,
        items: [
          { name: 'TV Unit', description: '', pricingMethod: 'per_sqft', defaultQuantity: 1, unit: 'sq.ft', width: 7, height: 7, depth: 2, widthUnit: 'feet', heightUnit: 'feet', depthUnit: 'feet', matchKeyword: 'TV Unit', isOptional: false, scopes: ['essential', 'standard', 'complete'] },
          { name: 'TV Back Panel', description: '', pricingMethod: 'per_sqft', defaultQuantity: 1, unit: 'sq.ft', width: 7, height: 4, widthUnit: 'feet', heightUnit: 'feet', matchKeyword: 'TV Back Panel', isOptional: false, scopes: ['standard', 'complete'] },
          { name: 'TV Storage / Base Unit', description: '', pricingMethod: 'per_sqft', defaultQuantity: 1, unit: 'sq.ft', width: 7, height: 2, depth: 2, widthUnit: 'feet', heightUnit: 'feet', depthUnit: 'feet', matchKeyword: 'TV Storage', isOptional: false, scopes: ['standard', 'complete'] },
          { name: 'Shoe Rack', description: '', pricingMethod: 'per_sqft', defaultQuantity: 1, unit: 'sq.ft', width: 4, height: 7, depth: 1.5, widthUnit: 'feet', heightUnit: 'feet', depthUnit: 'feet', matchKeyword: 'Shoe Rack', isOptional: false, scopes: ['standard', 'complete'] },
          { name: 'Pooja Unit', description: '', pricingMethod: 'per_sqft', defaultQuantity: 1, unit: 'sq.ft', width: 4, height: 7, depth: 1.5, widthUnit: 'feet', heightUnit: 'feet', depthUnit: 'feet', matchKeyword: 'Pooja Unit', isOptional: true, scopes: ['complete'] },
          { name: 'Crockery Unit', description: 'Living room crockery display', pricingMethod: 'per_sqft', defaultQuantity: 1, unit: 'sq.ft', width: 5, height: 7, depth: 1.5, widthUnit: 'feet', heightUnit: 'feet', depthUnit: 'feet', matchKeyword: 'Crockery', isOptional: true, scopes: ['complete'] },
          { name: 'Decorative Partition', description: '', pricingMethod: 'per_sqft', defaultQuantity: 1, unit: 'sq.ft', width: 5, height: 7, widthUnit: 'feet', heightUnit: 'feet', matchKeyword: 'Partition', isOptional: true, scopes: ['complete'] },
          { name: 'False Ceiling', description: 'Living room false ceiling with LED lighting', pricingMethod: 'per_sqft', defaultQuantity: 200, unit: 'sq.ft', matchKeyword: 'False Ceiling', isOptional: true, scopes: ['complete'] },
        ],
      },
      {
        id: 'bedroom1',
        name: 'Master Bedroom',
        icon: 'bed',
        defaultIncluded: true,
        items: [
          { name: 'King Bed', description: 'King size bed with storage', pricingMethod: 'per_unit', defaultQuantity: 1, unit: 'unit', matchKeyword: 'Bed', isOptional: false, scopes: ['essential', 'standard', 'complete'] },
          { name: 'Bed Back Panel', description: '', pricingMethod: 'per_sqft', defaultQuantity: 1, unit: 'sq.ft', width: 6, height: 4, widthUnit: 'feet', heightUnit: 'feet', matchKeyword: 'Bed Back Panel', isOptional: false, scopes: ['standard', 'complete'] },
          { name: 'Bedside Tables', description: '2 bedside tables', pricingMethod: 'per_unit', defaultQuantity: 2, unit: 'unit', matchKeyword: 'Bedside Table', isOptional: false, scopes: ['standard', 'complete'] },
          { name: 'Wardrobe', description: 'Material: HDHMR, Finish: Laminate, Hardware: Soft Close, Loft: Yes', pricingMethod: 'per_sqft', defaultQuantity: 1, unit: 'sq.ft', width: 8, height: 7, depth: 2, widthUnit: 'feet', heightUnit: 'feet', depthUnit: 'feet', matchKeyword: 'Wardrobe', isOptional: false, scopes: ['essential', 'standard', 'complete'] },
          { name: 'Loft above Wardrobe', description: '', pricingMethod: 'per_sqft', defaultQuantity: 1, unit: 'sq.ft', width: 8, height: 2, depth: 2, widthUnit: 'feet', heightUnit: 'feet', depthUnit: 'feet', matchKeyword: 'Loft', isOptional: false, scopes: ['standard', 'complete'] },
          { name: 'Dressing Unit', description: '', pricingMethod: 'per_sqft', defaultQuantity: 1, unit: 'sq.ft', width: 4, height: 7, depth: 1.5, widthUnit: 'feet', heightUnit: 'feet', depthUnit: 'feet', matchKeyword: 'Dressing', isOptional: false, scopes: ['standard', 'complete'] },
          { name: 'Study / Workstation', description: '', pricingMethod: 'per_unit', defaultQuantity: 1, unit: 'unit', matchKeyword: 'Study Table', isOptional: true, scopes: ['complete'] },
          { name: 'TV Unit', description: 'Bedroom TV unit', pricingMethod: 'per_sqft', defaultQuantity: 1, unit: 'sq.ft', width: 5, height: 5, depth: 2, widthUnit: 'feet', heightUnit: 'feet', depthUnit: 'feet', matchKeyword: 'TV Unit', isOptional: true, scopes: ['complete'] },
        ],
      },
      {
        id: 'bedroom2',
        name: 'Bedroom 2',
        icon: 'bed',
        defaultIncluded: true,
        items: [
          { name: 'Queen Bed', description: 'Queen size bed with storage', pricingMethod: 'per_unit', defaultQuantity: 1, unit: 'unit', matchKeyword: 'Bed', isOptional: false, scopes: ['essential', 'standard', 'complete'] },
          { name: 'Bed Back Panel', description: '', pricingMethod: 'per_sqft', defaultQuantity: 1, unit: 'sq.ft', width: 5, height: 4, widthUnit: 'feet', heightUnit: 'feet', matchKeyword: 'Bed Back Panel', isOptional: false, scopes: ['standard', 'complete'] },
          { name: 'Bedside Tables', description: '2 bedside tables', pricingMethod: 'per_unit', defaultQuantity: 2, unit: 'unit', matchKeyword: 'Bedside Table', isOptional: false, scopes: ['standard', 'complete'] },
          { name: 'Wardrobe', description: 'Material: HDHMR, Finish: Laminate, Hardware: Soft Close, Loft: Yes', pricingMethod: 'per_sqft', defaultQuantity: 1, unit: 'sq.ft', width: 7, height: 7, depth: 2, widthUnit: 'feet', heightUnit: 'feet', depthUnit: 'feet', matchKeyword: 'Wardrobe', isOptional: false, scopes: ['essential', 'standard', 'complete'] },
          { name: 'Loft above Wardrobe', description: '', pricingMethod: 'per_sqft', defaultQuantity: 1, unit: 'sq.ft', width: 7, height: 2, depth: 2, widthUnit: 'feet', heightUnit: 'feet', depthUnit: 'feet', matchKeyword: 'Loft', isOptional: false, scopes: ['standard', 'complete'] },
          { name: 'Dressing / Study', description: 'Combined dressing and study area', pricingMethod: 'per_sqft', defaultQuantity: 1, unit: 'sq.ft', width: 4, height: 7, depth: 1.5, widthUnit: 'feet', heightUnit: 'feet', depthUnit: 'feet', matchKeyword: 'Dressing', isOptional: true, scopes: ['standard', 'complete'] },
          { name: 'Bookshelf', description: '', pricingMethod: 'per_sqft', defaultQuantity: 1, unit: 'sq.ft', width: 4, height: 7, depth: 1, widthUnit: 'feet', heightUnit: 'feet', depthUnit: 'feet', matchKeyword: 'Bookshelf', isOptional: true, scopes: ['complete'] },
        ],
      },
      {
        id: 'kitchen',
        name: 'Kitchen',
        icon: 'cooking',
        defaultIncluded: true,
        items: [
          { name: 'Base Cabinets', description: 'Kitchen base cabinets with drawers, tandem, corner unit, sink unit', pricingMethod: 'per_running_ft', defaultQuantity: 12, unit: 'running ft', matchKeyword: 'Kitchen Base', isOptional: false, scopes: ['essential', 'standard', 'complete'] },
          { name: 'Wall Cabinets', description: 'Overhead kitchen cabinets with lift-up shutters', pricingMethod: 'per_running_ft', defaultQuantity: 10, unit: 'running ft', matchKeyword: 'Kitchen Wall', isOptional: false, scopes: ['essential', 'standard', 'complete'] },
          { name: 'Tall Unit', description: 'Pantry tall unit with oven and microwave space', pricingMethod: 'per_sqft', defaultQuantity: 1, unit: 'sq.ft', width: 2, height: 7, depth: 2, widthUnit: 'feet', heightUnit: 'feet', depthUnit: 'feet', matchKeyword: 'Tall Unit', isOptional: true, scopes: ['standard', 'complete'] },
          { name: 'Loft', description: 'Kitchen loft', pricingMethod: 'per_running_ft', defaultQuantity: 12, unit: 'running ft', matchKeyword: 'Kitchen Loft', isOptional: true, scopes: ['standard', 'complete'] },
          { name: 'Chimney', description: 'Appliance - supplied by homeowner unless noted', pricingMethod: 'per_unit', defaultQuantity: 1, unit: 'unit', matchKeyword: 'Chimney', isOptional: true, scopes: ['complete'] },
          { name: 'Hob', description: 'Appliance - supplied by homeowner unless noted', pricingMethod: 'per_unit', defaultQuantity: 1, unit: 'unit', matchKeyword: 'Hob', isOptional: true, scopes: ['complete'] },
          { name: 'Built-in Oven', description: 'Appliance - supplied by homeowner unless noted', pricingMethod: 'per_unit', defaultQuantity: 1, unit: 'unit', matchKeyword: 'Oven', isOptional: true, scopes: ['complete'] },
          { name: 'Dishwasher', description: 'Appliance - supplied by homeowner unless noted', pricingMethod: 'per_unit', defaultQuantity: 1, unit: 'unit', matchKeyword: 'Dishwasher', isOptional: true, scopes: ['complete'] },
        ],
      },
      {
        id: 'dining',
        name: 'Dining',
        icon: 'utensils',
        defaultIncluded: true,
        items: [
          { name: 'Crockery Unit', description: '', pricingMethod: 'per_sqft', defaultQuantity: 1, unit: 'sq.ft', width: 5, height: 7, depth: 1.5, widthUnit: 'feet', heightUnit: 'feet', depthUnit: 'feet', matchKeyword: 'Crockery', isOptional: false, scopes: ['standard', 'complete'] },
          { name: 'Dining Back Panel', description: '', pricingMethod: 'per_sqft', defaultQuantity: 1, unit: 'sq.ft', width: 6, height: 4, widthUnit: 'feet', heightUnit: 'feet', matchKeyword: 'Dining Back Panel', isOptional: true, scopes: ['complete'] },
          { name: 'Bar Unit', description: '', pricingMethod: 'per_unit', defaultQuantity: 1, unit: 'unit', matchKeyword: 'Bar Unit', isOptional: true, scopes: ['complete'] },
        ],
      },
      {
        id: 'entrance',
        name: 'Entrance / Foyer',
        icon: 'door',
        defaultIncluded: true,
        items: [
          { name: 'Shoe Rack', description: 'Entrance shoe rack with seating bench', pricingMethod: 'per_sqft', defaultQuantity: 1, unit: 'sq.ft', width: 4, height: 7, depth: 1.5, widthUnit: 'feet', heightUnit: 'feet', depthUnit: 'feet', matchKeyword: 'Shoe Rack', isOptional: false, scopes: ['standard', 'complete'] },
          { name: 'Seating Bench', description: '', pricingMethod: 'per_unit', defaultQuantity: 1, unit: 'unit', matchKeyword: 'Seating Bench', isOptional: false, scopes: ['standard', 'complete'] },
          { name: 'Full-height Mirror', description: '', pricingMethod: 'per_sqft', defaultQuantity: 1, unit: 'sq.ft', width: 2, height: 6, widthUnit: 'feet', heightUnit: 'feet', matchKeyword: 'Mirror', isOptional: true, scopes: ['complete'] },
          { name: 'Console Table', description: '', pricingMethod: 'per_unit', defaultQuantity: 1, unit: 'unit', matchKeyword: 'Console', isOptional: true, scopes: ['complete'] },
        ],
      },
      {
        id: 'utility',
        name: 'Utility Area',
        icon: 'washing-machine',
        defaultIncluded: false,
        items: [
          { name: 'Washing Machine Cabinet', description: '', pricingMethod: 'per_sqft', defaultQuantity: 1, unit: 'sq.ft', width: 3, height: 7, depth: 2, widthUnit: 'feet', heightUnit: 'feet', depthUnit: 'feet', matchKeyword: 'Utility Cabinet', isOptional: false, scopes: ['standard', 'complete'] },
          { name: 'Overhead Storage', description: '', pricingMethod: 'per_sqft', defaultQuantity: 1, unit: 'sq.ft', width: 4, height: 3, depth: 1.5, widthUnit: 'feet', heightUnit: 'feet', depthUnit: 'feet', matchKeyword: 'Overhead Storage', isOptional: false, scopes: ['standard', 'complete'] },
        ],
      },
      {
        id: 'bathroom',
        name: 'Bathroom',
        icon: 'shower',
        defaultIncluded: false,
        items: [
          { name: 'Vanity Unit', description: 'Bathroom vanity with sink and storage', pricingMethod: 'per_unit', defaultQuantity: 2, unit: 'unit', matchKeyword: 'Vanity', isOptional: false, scopes: ['complete'] },
          { name: 'Mirror Cabinet', description: '', pricingMethod: 'per_unit', defaultQuantity: 2, unit: 'unit', matchKeyword: 'Mirror Cabinet', isOptional: true, scopes: ['complete'] },
          { name: 'Shower Partition', description: '', pricingMethod: 'per_unit', defaultQuantity: 2, unit: 'unit', matchKeyword: 'Shower Partition', isOptional: true, scopes: ['complete'] },
        ],
      },
      {
        id: 'electrical',
        name: 'Electrical',
        icon: 'zap',
        defaultIncluded: false,
        items: [
          { name: 'Additional Light Points', description: '', pricingMethod: 'per_unit', defaultQuantity: 15, unit: 'unit', matchKeyword: 'Light Point', isOptional: false, scopes: ['complete'] },
          { name: 'Fan Points', description: '', pricingMethod: 'per_unit', defaultQuantity: 3, unit: 'unit', matchKeyword: 'Fan Point', isOptional: false, scopes: ['complete'] },
          { name: 'AC Points', description: '', pricingMethod: 'per_unit', defaultQuantity: 2, unit: 'unit', matchKeyword: 'AC Point', isOptional: false, scopes: ['complete'] },
          { name: 'TV Points', description: '', pricingMethod: 'per_unit', defaultQuantity: 2, unit: 'unit', matchKeyword: 'TV Point', isOptional: false, scopes: ['complete'] },
          { name: 'LED Strip Lighting', description: '', pricingMethod: 'per_unit', defaultQuantity: 8, unit: 'unit', matchKeyword: 'LED Strip', isOptional: true, scopes: ['complete'] },
          { name: 'Pendant Lighting', description: '', pricingMethod: 'per_unit', defaultQuantity: 3, unit: 'unit', matchKeyword: 'Pendant Light', isOptional: true, scopes: ['complete'] },
        ],
      },
      {
        id: 'painting',
        name: 'Painting / Wall Finishes',
        icon: 'paintbrush',
        defaultIncluded: false,
        items: [
          { name: 'Interior Painting', description: 'Premium emulsion paint for all walls', pricingMethod: 'per_sqft', defaultQuantity: 600, unit: 'sq.ft', matchKeyword: 'Painting', isOptional: false, scopes: ['complete'] },
          { name: 'Wall Panelling', description: 'Decorative wall panel', pricingMethod: 'per_sqft', defaultQuantity: 80, unit: 'sq.ft', matchKeyword: 'Wall Panel', isOptional: true, scopes: ['complete'] },
          { name: 'Wallpaper', description: '', pricingMethod: 'per_sqft', defaultQuantity: 100, unit: 'sq.ft', matchKeyword: 'Wallpaper', isOptional: true, scopes: ['complete'] },
        ],
      },
    ],
  },

  {
    id: '3bhk',
    name: '3 BHK',
    bedrooms: 3,
    description: '3 Bedrooms, Living, Kitchen, Dining',
    rooms: [
      {
        id: 'living',
        name: 'Living Room',
        icon: 'sofa',
        defaultIncluded: true,
        items: [
          { name: 'TV Unit', description: '', pricingMethod: 'per_sqft', defaultQuantity: 1, unit: 'sq.ft', width: 8, height: 7, depth: 2, widthUnit: 'feet', heightUnit: 'feet', depthUnit: 'feet', matchKeyword: 'TV Unit', isOptional: false, scopes: ['essential', 'standard', 'complete'] },
          { name: 'TV Back Panel', description: '', pricingMethod: 'per_sqft', defaultQuantity: 1, unit: 'sq.ft', width: 8, height: 4, widthUnit: 'feet', heightUnit: 'feet', matchKeyword: 'TV Back Panel', isOptional: false, scopes: ['standard', 'complete'] },
          { name: 'TV Storage / Base Unit', description: '', pricingMethod: 'per_sqft', defaultQuantity: 1, unit: 'sq.ft', width: 8, height: 2, depth: 2, widthUnit: 'feet', heightUnit: 'feet', depthUnit: 'feet', matchKeyword: 'TV Storage', isOptional: false, scopes: ['standard', 'complete'] },
          { name: 'Shoe Rack', description: '', pricingMethod: 'per_sqft', defaultQuantity: 1, unit: 'sq.ft', width: 5, height: 7, depth: 1.5, widthUnit: 'feet', heightUnit: 'feet', depthUnit: 'feet', matchKeyword: 'Shoe Rack', isOptional: false, scopes: ['standard', 'complete'] },
          { name: 'Pooja Unit', description: '', pricingMethod: 'per_sqft', defaultQuantity: 1, unit: 'sq.ft', width: 5, height: 7, depth: 1.5, widthUnit: 'feet', heightUnit: 'feet', depthUnit: 'feet', matchKeyword: 'Pooja Unit', isOptional: true, scopes: ['complete'] },
          { name: 'Crockery Unit', description: '', pricingMethod: 'per_sqft', defaultQuantity: 1, unit: 'sq.ft', width: 6, height: 7, depth: 1.5, widthUnit: 'feet', heightUnit: 'feet', depthUnit: 'feet', matchKeyword: 'Crockery', isOptional: true, scopes: ['complete'] },
          { name: 'Decorative Partition', description: '', pricingMethod: 'per_sqft', defaultQuantity: 1, unit: 'sq.ft', width: 6, height: 7, widthUnit: 'feet', heightUnit: 'feet', matchKeyword: 'Partition', isOptional: true, scopes: ['complete'] },
          { name: 'Wall Panelling', description: '', pricingMethod: 'per_sqft', defaultQuantity: 80, unit: 'sq.ft', matchKeyword: 'Wall Panel', isOptional: true, scopes: ['complete'] },
          { name: 'False Ceiling', description: 'Living room false ceiling with LED lighting', pricingMethod: 'per_sqft', defaultQuantity: 250, unit: 'sq.ft', matchKeyword: 'False Ceiling', isOptional: true, scopes: ['complete'] },
        ],
      },
      {
        id: 'bedroom1',
        name: 'Master Bedroom',
        icon: 'bed',
        defaultIncluded: true,
        items: [
          { name: 'King Bed', description: 'King size bed with storage', pricingMethod: 'per_unit', defaultQuantity: 1, unit: 'unit', matchKeyword: 'Bed', isOptional: false, scopes: ['essential', 'standard', 'complete'] },
          { name: 'Bed Back Panel', description: '', pricingMethod: 'per_sqft', defaultQuantity: 1, unit: 'sq.ft', width: 6, height: 4, widthUnit: 'feet', heightUnit: 'feet', matchKeyword: 'Bed Back Panel', isOptional: false, scopes: ['standard', 'complete'] },
          { name: 'Bedside Tables', description: '2 bedside tables', pricingMethod: 'per_unit', defaultQuantity: 2, unit: 'unit', matchKeyword: 'Bedside Table', isOptional: false, scopes: ['standard', 'complete'] },
          { name: 'Wardrobe', description: 'Material: HDHMR, Finish: Laminate, Hardware: Soft Close, Loft: Yes', pricingMethod: 'per_sqft', defaultQuantity: 1, unit: 'sq.ft', width: 9, height: 7, depth: 2, widthUnit: 'feet', heightUnit: 'feet', depthUnit: 'feet', matchKeyword: 'Wardrobe', isOptional: false, scopes: ['essential', 'standard', 'complete'] },
          { name: 'Loft above Wardrobe', description: '', pricingMethod: 'per_sqft', defaultQuantity: 1, unit: 'sq.ft', width: 9, height: 2, depth: 2, widthUnit: 'feet', heightUnit: 'feet', depthUnit: 'feet', matchKeyword: 'Loft', isOptional: false, scopes: ['standard', 'complete'] },
          { name: 'Dressing Unit', description: '', pricingMethod: 'per_sqft', defaultQuantity: 1, unit: 'sq.ft', width: 5, height: 7, depth: 1.5, widthUnit: 'feet', heightUnit: 'feet', depthUnit: 'feet', matchKeyword: 'Dressing', isOptional: false, scopes: ['standard', 'complete'] },
          { name: 'Study / Workstation', description: '', pricingMethod: 'per_unit', defaultQuantity: 1, unit: 'unit', matchKeyword: 'Study Table', isOptional: true, scopes: ['complete'] },
          { name: 'TV Unit', description: 'Bedroom TV unit', pricingMethod: 'per_sqft', defaultQuantity: 1, unit: 'sq.ft', width: 5, height: 5, depth: 2, widthUnit: 'feet', heightUnit: 'feet', depthUnit: 'feet', matchKeyword: 'TV Unit', isOptional: true, scopes: ['complete'] },
        ],
      },
      {
        id: 'bedroom2',
        name: 'Bedroom 2',
        icon: 'bed',
        defaultIncluded: true,
        items: [
          { name: 'Queen Bed', description: 'Queen size bed with storage', pricingMethod: 'per_unit', defaultQuantity: 1, unit: 'unit', matchKeyword: 'Bed', isOptional: false, scopes: ['essential', 'standard', 'complete'] },
          { name: 'Bed Back Panel', description: '', pricingMethod: 'per_sqft', defaultQuantity: 1, unit: 'sq.ft', width: 5, height: 4, widthUnit: 'feet', heightUnit: 'feet', matchKeyword: 'Bed Back Panel', isOptional: false, scopes: ['standard', 'complete'] },
          { name: 'Bedside Tables', description: '2 bedside tables', pricingMethod: 'per_unit', defaultQuantity: 2, unit: 'unit', matchKeyword: 'Bedside Table', isOptional: false, scopes: ['standard', 'complete'] },
          { name: 'Wardrobe', description: 'Material: HDHMR, Finish: Laminate, Hardware: Soft Close, Loft: Yes', pricingMethod: 'per_sqft', defaultQuantity: 1, unit: 'sq.ft', width: 8, height: 7, depth: 2, widthUnit: 'feet', heightUnit: 'feet', depthUnit: 'feet', matchKeyword: 'Wardrobe', isOptional: false, scopes: ['essential', 'standard', 'complete'] },
          { name: 'Loft above Wardrobe', description: '', pricingMethod: 'per_sqft', defaultQuantity: 1, unit: 'sq.ft', width: 8, height: 2, depth: 2, widthUnit: 'feet', heightUnit: 'feet', depthUnit: 'feet', matchKeyword: 'Loft', isOptional: false, scopes: ['standard', 'complete'] },
          { name: 'Dressing / Study', description: '', pricingMethod: 'per_sqft', defaultQuantity: 1, unit: 'sq.ft', width: 4, height: 7, depth: 1.5, widthUnit: 'feet', heightUnit: 'feet', depthUnit: 'feet', matchKeyword: 'Dressing', isOptional: true, scopes: ['standard', 'complete'] },
        ],
      },
      {
        id: 'bedroom3',
        name: 'Bedroom 3',
        icon: 'bed',
        defaultIncluded: true,
        items: [
          { name: 'Queen Bed', description: 'Queen size bed with storage', pricingMethod: 'per_unit', defaultQuantity: 1, unit: 'unit', matchKeyword: 'Bed', isOptional: false, scopes: ['essential', 'standard', 'complete'] },
          { name: 'Bed Back Panel', description: '', pricingMethod: 'per_sqft', defaultQuantity: 1, unit: 'sq.ft', width: 5, height: 4, widthUnit: 'feet', heightUnit: 'feet', matchKeyword: 'Bed Back Panel', isOptional: false, scopes: ['standard', 'complete'] },
          { name: 'Bedside Tables', description: '2 bedside tables', pricingMethod: 'per_unit', defaultQuantity: 2, unit: 'unit', matchKeyword: 'Bedside Table', isOptional: false, scopes: ['standard', 'complete'] },
          { name: 'Wardrobe', description: 'Material: HDHMR, Finish: Laminate, Hardware: Soft Close, Loft: Yes', pricingMethod: 'per_sqft', defaultQuantity: 1, unit: 'sq.ft', width: 7, height: 7, depth: 2, widthUnit: 'feet', heightUnit: 'feet', depthUnit: 'feet', matchKeyword: 'Wardrobe', isOptional: false, scopes: ['essential', 'standard', 'complete'] },
          { name: 'Loft above Wardrobe', description: '', pricingMethod: 'per_sqft', defaultQuantity: 1, unit: 'sq.ft', width: 7, height: 2, depth: 2, widthUnit: 'feet', heightUnit: 'feet', depthUnit: 'feet', matchKeyword: 'Loft', isOptional: false, scopes: ['standard', 'complete'] },
          { name: 'Study Table', description: '', pricingMethod: 'per_unit', defaultQuantity: 1, unit: 'unit', matchKeyword: 'Study Table', isOptional: true, scopes: ['complete'] },
        ],
      },
      {
        id: 'kitchen',
        name: 'Kitchen',
        icon: 'cooking',
        defaultIncluded: true,
        items: [
          { name: 'Base Cabinets', description: 'Kitchen base cabinets with drawers, tandem, corner unit, sink unit', pricingMethod: 'per_running_ft', defaultQuantity: 14, unit: 'running ft', matchKeyword: 'Kitchen Base', isOptional: false, scopes: ['essential', 'standard', 'complete'] },
          { name: 'Wall Cabinets', description: 'Overhead kitchen cabinets with lift-up shutters', pricingMethod: 'per_running_ft', defaultQuantity: 12, unit: 'running ft', matchKeyword: 'Kitchen Wall', isOptional: false, scopes: ['essential', 'standard', 'complete'] },
          { name: 'Tall Unit', description: 'Pantry tall unit with oven and microwave space', pricingMethod: 'per_sqft', defaultQuantity: 1, unit: 'sq.ft', width: 2, height: 7, depth: 2, widthUnit: 'feet', heightUnit: 'feet', depthUnit: 'feet', matchKeyword: 'Tall Unit', isOptional: true, scopes: ['standard', 'complete'] },
          { name: 'Loft', description: 'Kitchen loft', pricingMethod: 'per_running_ft', defaultQuantity: 14, unit: 'running ft', matchKeyword: 'Kitchen Loft', isOptional: true, scopes: ['standard', 'complete'] },
          { name: 'Chimney', description: 'Appliance - supplied by homeowner unless noted', pricingMethod: 'per_unit', defaultQuantity: 1, unit: 'unit', matchKeyword: 'Chimney', isOptional: true, scopes: ['complete'] },
          { name: 'Hob', description: 'Appliance - supplied by homeowner unless noted', pricingMethod: 'per_unit', defaultQuantity: 1, unit: 'unit', matchKeyword: 'Hob', isOptional: true, scopes: ['complete'] },
          { name: 'Built-in Oven', description: 'Appliance - supplied by homeowner unless noted', pricingMethod: 'per_unit', defaultQuantity: 1, unit: 'unit', matchKeyword: 'Oven', isOptional: true, scopes: ['complete'] },
          { name: 'Dishwasher', description: 'Appliance - supplied by homeowner unless noted', pricingMethod: 'per_unit', defaultQuantity: 1, unit: 'unit', matchKeyword: 'Dishwasher', isOptional: true, scopes: ['complete'] },
        ],
      },
      {
        id: 'dining',
        name: 'Dining',
        icon: 'utensils',
        defaultIncluded: true,
        items: [
          { name: 'Crockery Unit', description: '', pricingMethod: 'per_sqft', defaultQuantity: 1, unit: 'sq.ft', width: 6, height: 7, depth: 1.5, widthUnit: 'feet', heightUnit: 'feet', depthUnit: 'feet', matchKeyword: 'Crockery', isOptional: false, scopes: ['standard', 'complete'] },
          { name: 'Dining Back Panel', description: '', pricingMethod: 'per_sqft', defaultQuantity: 1, unit: 'sq.ft', width: 7, height: 4, widthUnit: 'feet', heightUnit: 'feet', matchKeyword: 'Dining Back Panel', isOptional: true, scopes: ['complete'] },
          { name: 'Bar Unit', description: '', pricingMethod: 'per_unit', defaultQuantity: 1, unit: 'unit', matchKeyword: 'Bar Unit', isOptional: true, scopes: ['complete'] },
        ],
      },
      {
        id: 'entrance',
        name: 'Entrance / Foyer',
        icon: 'door',
        defaultIncluded: true,
        items: [
          { name: 'Shoe Rack', description: 'Entrance shoe rack with seating bench', pricingMethod: 'per_sqft', defaultQuantity: 1, unit: 'sq.ft', width: 5, height: 7, depth: 1.5, widthUnit: 'feet', heightUnit: 'feet', depthUnit: 'feet', matchKeyword: 'Shoe Rack', isOptional: false, scopes: ['standard', 'complete'] },
          { name: 'Seating Bench', description: '', pricingMethod: 'per_unit', defaultQuantity: 1, unit: 'unit', matchKeyword: 'Seating Bench', isOptional: false, scopes: ['standard', 'complete'] },
          { name: 'Full-height Mirror', description: '', pricingMethod: 'per_sqft', defaultQuantity: 1, unit: 'sq.ft', width: 2, height: 6, widthUnit: 'feet', heightUnit: 'feet', matchKeyword: 'Mirror', isOptional: true, scopes: ['complete'] },
          { name: 'Console Table', description: '', pricingMethod: 'per_unit', defaultQuantity: 1, unit: 'unit', matchKeyword: 'Console', isOptional: true, scopes: ['complete'] },
          { name: 'Decorative Panel', description: '', pricingMethod: 'per_sqft', defaultQuantity: 1, unit: 'sq.ft', width: 5, height: 7, widthUnit: 'feet', heightUnit: 'feet', matchKeyword: 'Decorative Panel', isOptional: true, scopes: ['complete'] },
        ],
      },
      {
        id: 'utility',
        name: 'Utility Area',
        icon: 'washing-machine',
        defaultIncluded: false,
        items: [
          { name: 'Washing Machine Cabinet', description: '', pricingMethod: 'per_sqft', defaultQuantity: 1, unit: 'sq.ft', width: 3, height: 7, depth: 2, widthUnit: 'feet', heightUnit: 'feet', depthUnit: 'feet', matchKeyword: 'Utility Cabinet', isOptional: false, scopes: ['standard', 'complete'] },
          { name: 'Overhead Storage', description: '', pricingMethod: 'per_sqft', defaultQuantity: 1, unit: 'sq.ft', width: 4, height: 3, depth: 1.5, widthUnit: 'feet', heightUnit: 'feet', depthUnit: 'feet', matchKeyword: 'Overhead Storage', isOptional: false, scopes: ['standard', 'complete'] },
        ],
      },
      {
        id: 'bathroom',
        name: 'Bathroom',
        icon: 'shower',
        defaultIncluded: false,
        items: [
          { name: 'Vanity Unit', description: 'Bathroom vanity with sink and storage', pricingMethod: 'per_unit', defaultQuantity: 3, unit: 'unit', matchKeyword: 'Vanity', isOptional: false, scopes: ['complete'] },
          { name: 'Mirror Cabinet', description: '', pricingMethod: 'per_unit', defaultQuantity: 3, unit: 'unit', matchKeyword: 'Mirror Cabinet', isOptional: true, scopes: ['complete'] },
          { name: 'Shower Partition', description: '', pricingMethod: 'per_unit', defaultQuantity: 3, unit: 'unit', matchKeyword: 'Shower Partition', isOptional: true, scopes: ['complete'] },
        ],
      },
      {
        id: 'electrical',
        name: 'Electrical',
        icon: 'zap',
        defaultIncluded: false,
        items: [
          { name: 'Additional Light Points', description: '', pricingMethod: 'per_unit', defaultQuantity: 20, unit: 'unit', matchKeyword: 'Light Point', isOptional: false, scopes: ['complete'] },
          { name: 'Fan Points', description: '', pricingMethod: 'per_unit', defaultQuantity: 4, unit: 'unit', matchKeyword: 'Fan Point', isOptional: false, scopes: ['complete'] },
          { name: 'AC Points', description: '', pricingMethod: 'per_unit', defaultQuantity: 3, unit: 'unit', matchKeyword: 'AC Point', isOptional: false, scopes: ['complete'] },
          { name: 'TV Points', description: '', pricingMethod: 'per_unit', defaultQuantity: 3, unit: 'unit', matchKeyword: 'TV Point', isOptional: false, scopes: ['complete'] },
          { name: 'LED Strip Lighting', description: '', pricingMethod: 'per_unit', defaultQuantity: 10, unit: 'unit', matchKeyword: 'LED Strip', isOptional: true, scopes: ['complete'] },
          { name: 'Pendant Lighting', description: '', pricingMethod: 'per_unit', defaultQuantity: 4, unit: 'unit', matchKeyword: 'Pendant Light', isOptional: true, scopes: ['complete'] },
        ],
      },
      {
        id: 'painting',
        name: 'Painting / Wall Finishes',
        icon: 'paintbrush',
        defaultIncluded: false,
        items: [
          { name: 'Interior Painting', description: 'Premium emulsion paint for all walls', pricingMethod: 'per_sqft', defaultQuantity: 800, unit: 'sq.ft', matchKeyword: 'Painting', isOptional: false, scopes: ['complete'] },
          { name: 'Wall Panelling', description: 'Decorative wall panel', pricingMethod: 'per_sqft', defaultQuantity: 100, unit: 'sq.ft', matchKeyword: 'Wall Panel', isOptional: true, scopes: ['complete'] },
          { name: 'Wallpaper', description: '', pricingMethod: 'per_sqft', defaultQuantity: 120, unit: 'sq.ft', matchKeyword: 'Wallpaper', isOptional: true, scopes: ['complete'] },
        ],
      },
    ],
  },

  {
    id: '4bhk',
    name: '4 BHK',
    bedrooms: 4,
    description: '4 Bedrooms, Living, Kitchen, Dining',
    rooms: [
      {
        id: 'living',
        name: 'Living Room',
        icon: 'sofa',
        defaultIncluded: true,
        items: [
          { name: 'TV Unit', description: '', pricingMethod: 'per_sqft', defaultQuantity: 1, unit: 'sq.ft', width: 9, height: 7, depth: 2, widthUnit: 'feet', heightUnit: 'feet', depthUnit: 'feet', matchKeyword: 'TV Unit', isOptional: false, scopes: ['essential', 'standard', 'complete'] },
          { name: 'TV Back Panel', description: '', pricingMethod: 'per_sqft', defaultQuantity: 1, unit: 'sq.ft', width: 9, height: 4, widthUnit: 'feet', heightUnit: 'feet', matchKeyword: 'TV Back Panel', isOptional: false, scopes: ['standard', 'complete'] },
          { name: 'TV Storage / Base Unit', description: '', pricingMethod: 'per_sqft', defaultQuantity: 1, unit: 'sq.ft', width: 9, height: 2, depth: 2, widthUnit: 'feet', heightUnit: 'feet', depthUnit: 'feet', matchKeyword: 'TV Storage', isOptional: false, scopes: ['standard', 'complete'] },
          { name: 'Shoe Rack', description: '', pricingMethod: 'per_sqft', defaultQuantity: 1, unit: 'sq.ft', width: 5, height: 7, depth: 1.5, widthUnit: 'feet', heightUnit: 'feet', depthUnit: 'feet', matchKeyword: 'Shoe Rack', isOptional: false, scopes: ['standard', 'complete'] },
          { name: 'Pooja Unit', description: '', pricingMethod: 'per_sqft', defaultQuantity: 1, unit: 'sq.ft', width: 5, height: 7, depth: 1.5, widthUnit: 'feet', heightUnit: 'feet', depthUnit: 'feet', matchKeyword: 'Pooja Unit', isOptional: true, scopes: ['complete'] },
          { name: 'Crockery Unit', description: '', pricingMethod: 'per_sqft', defaultQuantity: 1, unit: 'sq.ft', width: 6, height: 7, depth: 1.5, widthUnit: 'feet', heightUnit: 'feet', depthUnit: 'feet', matchKeyword: 'Crockery', isOptional: true, scopes: ['complete'] },
          { name: 'Decorative Partition', description: '', pricingMethod: 'per_sqft', defaultQuantity: 1, unit: 'sq.ft', width: 6, height: 7, widthUnit: 'feet', heightUnit: 'feet', matchKeyword: 'Partition', isOptional: true, scopes: ['complete'] },
          { name: 'Wall Panelling', description: '', pricingMethod: 'per_sqft', defaultQuantity: 100, unit: 'sq.ft', matchKeyword: 'Wall Panel', isOptional: true, scopes: ['complete'] },
          { name: 'False Ceiling', description: 'Living room false ceiling with LED lighting', pricingMethod: 'per_sqft', defaultQuantity: 300, unit: 'sq.ft', matchKeyword: 'False Ceiling', isOptional: true, scopes: ['complete'] },
        ],
      },
      {
        id: 'bedroom1',
        name: 'Master Bedroom',
        icon: 'bed',
        defaultIncluded: true,
        items: [
          { name: 'King Bed', description: 'King size bed with storage', pricingMethod: 'per_unit', defaultQuantity: 1, unit: 'unit', matchKeyword: 'Bed', isOptional: false, scopes: ['essential', 'standard', 'complete'] },
          { name: 'Bed Back Panel', description: '', pricingMethod: 'per_sqft', defaultQuantity: 1, unit: 'sq.ft', width: 6, height: 4, widthUnit: 'feet', heightUnit: 'feet', matchKeyword: 'Bed Back Panel', isOptional: false, scopes: ['standard', 'complete'] },
          { name: 'Bedside Tables', description: '2 bedside tables', pricingMethod: 'per_unit', defaultQuantity: 2, unit: 'unit', matchKeyword: 'Bedside Table', isOptional: false, scopes: ['standard', 'complete'] },
          { name: 'Wardrobe', description: 'Material: HDHMR, Finish: Laminate, Hardware: Soft Close, Loft: Yes', pricingMethod: 'per_sqft', defaultQuantity: 1, unit: 'sq.ft', width: 10, height: 7, depth: 2, widthUnit: 'feet', heightUnit: 'feet', depthUnit: 'feet', matchKeyword: 'Wardrobe', isOptional: false, scopes: ['essential', 'standard', 'complete'] },
          { name: 'Loft above Wardrobe', description: '', pricingMethod: 'per_sqft', defaultQuantity: 1, unit: 'sq.ft', width: 10, height: 2, depth: 2, widthUnit: 'feet', heightUnit: 'feet', depthUnit: 'feet', matchKeyword: 'Loft', isOptional: false, scopes: ['standard', 'complete'] },
          { name: 'Dressing Unit', description: '', pricingMethod: 'per_sqft', defaultQuantity: 1, unit: 'sq.ft', width: 5, height: 7, depth: 1.5, widthUnit: 'feet', heightUnit: 'feet', depthUnit: 'feet', matchKeyword: 'Dressing', isOptional: false, scopes: ['standard', 'complete'] },
          { name: 'Study / Workstation', description: '', pricingMethod: 'per_unit', defaultQuantity: 1, unit: 'unit', matchKeyword: 'Study Table', isOptional: true, scopes: ['complete'] },
          { name: 'TV Unit', description: 'Bedroom TV unit', pricingMethod: 'per_sqft', defaultQuantity: 1, unit: 'sq.ft', width: 5, height: 5, depth: 2, widthUnit: 'feet', heightUnit: 'feet', depthUnit: 'feet', matchKeyword: 'TV Unit', isOptional: true, scopes: ['complete'] },
        ],
      },
      {
        id: 'bedroom2',
        name: 'Bedroom 2',
        icon: 'bed',
        defaultIncluded: true,
        items: [
          { name: 'Queen Bed', description: 'Queen size bed with storage', pricingMethod: 'per_unit', defaultQuantity: 1, unit: 'unit', matchKeyword: 'Bed', isOptional: false, scopes: ['essential', 'standard', 'complete'] },
          { name: 'Bed Back Panel', description: '', pricingMethod: 'per_sqft', defaultQuantity: 1, unit: 'sq.ft', width: 5, height: 4, widthUnit: 'feet', heightUnit: 'feet', matchKeyword: 'Bed Back Panel', isOptional: false, scopes: ['standard', 'complete'] },
          { name: 'Bedside Tables', description: '2 bedside tables', pricingMethod: 'per_unit', defaultQuantity: 2, unit: 'unit', matchKeyword: 'Bedside Table', isOptional: false, scopes: ['standard', 'complete'] },
          { name: 'Wardrobe', description: 'Material: HDHMR, Finish: Laminate, Hardware: Soft Close, Loft: Yes', pricingMethod: 'per_sqft', defaultQuantity: 1, unit: 'sq.ft', width: 8, height: 7, depth: 2, widthUnit: 'feet', heightUnit: 'feet', depthUnit: 'feet', matchKeyword: 'Wardrobe', isOptional: false, scopes: ['essential', 'standard', 'complete'] },
          { name: 'Loft above Wardrobe', description: '', pricingMethod: 'per_sqft', defaultQuantity: 1, unit: 'sq.ft', width: 8, height: 2, depth: 2, widthUnit: 'feet', heightUnit: 'feet', depthUnit: 'feet', matchKeyword: 'Loft', isOptional: false, scopes: ['standard', 'complete'] },
          { name: 'Dressing / Study', description: '', pricingMethod: 'per_sqft', defaultQuantity: 1, unit: 'sq.ft', width: 4, height: 7, depth: 1.5, widthUnit: 'feet', heightUnit: 'feet', depthUnit: 'feet', matchKeyword: 'Dressing', isOptional: true, scopes: ['standard', 'complete'] },
        ],
      },
      {
        id: 'bedroom3',
        name: 'Bedroom 3',
        icon: 'bed',
        defaultIncluded: true,
        items: [
          { name: 'Queen Bed', description: 'Queen size bed with storage', pricingMethod: 'per_unit', defaultQuantity: 1, unit: 'unit', matchKeyword: 'Bed', isOptional: false, scopes: ['essential', 'standard', 'complete'] },
          { name: 'Bed Back Panel', description: '', pricingMethod: 'per_sqft', defaultQuantity: 1, unit: 'sq.ft', width: 5, height: 4, widthUnit: 'feet', heightUnit: 'feet', matchKeyword: 'Bed Back Panel', isOptional: false, scopes: ['standard', 'complete'] },
          { name: 'Bedside Tables', description: '2 bedside tables', pricingMethod: 'per_unit', defaultQuantity: 2, unit: 'unit', matchKeyword: 'Bedside Table', isOptional: false, scopes: ['standard', 'complete'] },
          { name: 'Wardrobe', description: 'Material: HDHMR, Finish: Laminate, Hardware: Soft Close, Loft: Yes', pricingMethod: 'per_sqft', defaultQuantity: 1, unit: 'sq.ft', width: 7, height: 7, depth: 2, widthUnit: 'feet', heightUnit: 'feet', depthUnit: 'feet', matchKeyword: 'Wardrobe', isOptional: false, scopes: ['essential', 'standard', 'complete'] },
          { name: 'Loft above Wardrobe', description: '', pricingMethod: 'per_sqft', defaultQuantity: 1, unit: 'sq.ft', width: 7, height: 2, depth: 2, widthUnit: 'feet', heightUnit: 'feet', depthUnit: 'feet', matchKeyword: 'Loft', isOptional: false, scopes: ['standard', 'complete'] },
          { name: 'Study Table', description: '', pricingMethod: 'per_unit', defaultQuantity: 1, unit: 'unit', matchKeyword: 'Study Table', isOptional: true, scopes: ['complete'] },
        ],
      },
      {
        id: 'bedroom4',
        name: 'Bedroom 4',
        icon: 'bed',
        defaultIncluded: true,
        items: [
          { name: 'Single Bed', description: 'Single bed with storage', pricingMethod: 'per_unit', defaultQuantity: 1, unit: 'unit', matchKeyword: 'Bed', isOptional: false, scopes: ['essential', 'standard', 'complete'] },
          { name: 'Bed Back Panel', description: '', pricingMethod: 'per_sqft', defaultQuantity: 1, unit: 'sq.ft', width: 4, height: 4, widthUnit: 'feet', heightUnit: 'feet', matchKeyword: 'Bed Back Panel', isOptional: false, scopes: ['standard', 'complete'] },
          { name: 'Bedside Table', description: '', pricingMethod: 'per_unit', defaultQuantity: 1, unit: 'unit', matchKeyword: 'Bedside Table', isOptional: false, scopes: ['standard', 'complete'] },
          { name: 'Wardrobe', description: 'Material: HDHMR, Finish: Laminate, Hardware: Soft Close, Loft: Yes', pricingMethod: 'per_sqft', defaultQuantity: 1, unit: 'sq.ft', width: 6, height: 7, depth: 2, widthUnit: 'feet', heightUnit: 'feet', depthUnit: 'feet', matchKeyword: 'Wardrobe', isOptional: false, scopes: ['essential', 'standard', 'complete'] },
          { name: 'Loft above Wardrobe', description: '', pricingMethod: 'per_sqft', defaultQuantity: 1, unit: 'sq.ft', width: 6, height: 2, depth: 2, widthUnit: 'feet', heightUnit: 'feet', depthUnit: 'feet', matchKeyword: 'Loft', isOptional: false, scopes: ['standard', 'complete'] },
          { name: 'Study Table', description: '', pricingMethod: 'per_unit', defaultQuantity: 1, unit: 'unit', matchKeyword: 'Study Table', isOptional: true, scopes: ['complete'] },
          { name: 'Bookshelf', description: '', pricingMethod: 'per_sqft', defaultQuantity: 1, unit: 'sq.ft', width: 4, height: 7, depth: 1, widthUnit: 'feet', heightUnit: 'feet', depthUnit: 'feet', matchKeyword: 'Bookshelf', isOptional: true, scopes: ['complete'] },
        ],
      },
      {
        id: 'kitchen',
        name: 'Kitchen',
        icon: 'cooking',
        defaultIncluded: true,
        items: [
          { name: 'Base Cabinets', description: 'Kitchen base cabinets with drawers, tandem, corner unit, sink unit', pricingMethod: 'per_running_ft', defaultQuantity: 16, unit: 'running ft', matchKeyword: 'Kitchen Base', isOptional: false, scopes: ['essential', 'standard', 'complete'] },
          { name: 'Wall Cabinets', description: 'Overhead kitchen cabinets with lift-up shutters', pricingMethod: 'per_running_ft', defaultQuantity: 14, unit: 'running ft', matchKeyword: 'Kitchen Wall', isOptional: false, scopes: ['essential', 'standard', 'complete'] },
          { name: 'Tall Unit', description: 'Pantry tall unit with oven and microwave space', pricingMethod: 'per_sqft', defaultQuantity: 1, unit: 'sq.ft', width: 2, height: 7, depth: 2, widthUnit: 'feet', heightUnit: 'feet', depthUnit: 'feet', matchKeyword: 'Tall Unit', isOptional: true, scopes: ['standard', 'complete'] },
          { name: 'Loft', description: 'Kitchen loft', pricingMethod: 'per_running_ft', defaultQuantity: 16, unit: 'running ft', matchKeyword: 'Kitchen Loft', isOptional: true, scopes: ['standard', 'complete'] },
          { name: 'Chimney', description: 'Appliance - supplied by homeowner unless noted', pricingMethod: 'per_unit', defaultQuantity: 1, unit: 'unit', matchKeyword: 'Chimney', isOptional: true, scopes: ['complete'] },
          { name: 'Hob', description: 'Appliance - supplied by homeowner unless noted', pricingMethod: 'per_unit', defaultQuantity: 1, unit: 'unit', matchKeyword: 'Hob', isOptional: true, scopes: ['complete'] },
          { name: 'Built-in Oven', description: 'Appliance - supplied by homeowner unless noted', pricingMethod: 'per_unit', defaultQuantity: 1, unit: 'unit', matchKeyword: 'Oven', isOptional: true, scopes: ['complete'] },
          { name: 'Dishwasher', description: 'Appliance - supplied by homeowner unless noted', pricingMethod: 'per_unit', defaultQuantity: 1, unit: 'unit', matchKeyword: 'Dishwasher', isOptional: true, scopes: ['complete'] },
        ],
      },
      {
        id: 'dining',
        name: 'Dining',
        icon: 'utensils',
        defaultIncluded: true,
        items: [
          { name: 'Crockery Unit', description: '', pricingMethod: 'per_sqft', defaultQuantity: 1, unit: 'sq.ft', width: 6, height: 7, depth: 1.5, widthUnit: 'feet', heightUnit: 'feet', depthUnit: 'feet', matchKeyword: 'Crockery', isOptional: false, scopes: ['standard', 'complete'] },
          { name: 'Dining Back Panel', description: '', pricingMethod: 'per_sqft', defaultQuantity: 1, unit: 'sq.ft', width: 7, height: 4, widthUnit: 'feet', heightUnit: 'feet', matchKeyword: 'Dining Back Panel', isOptional: true, scopes: ['complete'] },
          { name: 'Bar Unit', description: '', pricingMethod: 'per_unit', defaultQuantity: 1, unit: 'unit', matchKeyword: 'Bar Unit', isOptional: true, scopes: ['complete'] },
        ],
      },
      {
        id: 'entrance',
        name: 'Entrance / Foyer',
        icon: 'door',
        defaultIncluded: true,
        items: [
          { name: 'Shoe Rack', description: 'Entrance shoe rack with seating bench', pricingMethod: 'per_sqft', defaultQuantity: 1, unit: 'sq.ft', width: 5, height: 7, depth: 1.5, widthUnit: 'feet', heightUnit: 'feet', depthUnit: 'feet', matchKeyword: 'Shoe Rack', isOptional: false, scopes: ['standard', 'complete'] },
          { name: 'Seating Bench', description: '', pricingMethod: 'per_unit', defaultQuantity: 1, unit: 'unit', matchKeyword: 'Seating Bench', isOptional: false, scopes: ['standard', 'complete'] },
          { name: 'Full-height Mirror', description: '', pricingMethod: 'per_sqft', defaultQuantity: 1, unit: 'sq.ft', width: 2, height: 6, widthUnit: 'feet', heightUnit: 'feet', matchKeyword: 'Mirror', isOptional: true, scopes: ['complete'] },
          { name: 'Console Table', description: '', pricingMethod: 'per_unit', defaultQuantity: 1, unit: 'unit', matchKeyword: 'Console', isOptional: true, scopes: ['complete'] },
          { name: 'Decorative Panel', description: '', pricingMethod: 'per_sqft', defaultQuantity: 1, unit: 'sq.ft', width: 5, height: 7, widthUnit: 'feet', heightUnit: 'feet', matchKeyword: 'Decorative Panel', isOptional: true, scopes: ['complete'] },
        ],
      },
      {
        id: 'utility',
        name: 'Utility Area',
        icon: 'washing-machine',
        defaultIncluded: false,
        items: [
          { name: 'Washing Machine Cabinet', description: '', pricingMethod: 'per_sqft', defaultQuantity: 1, unit: 'sq.ft', width: 3, height: 7, depth: 2, widthUnit: 'feet', heightUnit: 'feet', depthUnit: 'feet', matchKeyword: 'Utility Cabinet', isOptional: false, scopes: ['standard', 'complete'] },
          { name: 'Overhead Storage', description: '', pricingMethod: 'per_sqft', defaultQuantity: 1, unit: 'sq.ft', width: 4, height: 3, depth: 1.5, widthUnit: 'feet', heightUnit: 'feet', depthUnit: 'feet', matchKeyword: 'Overhead Storage', isOptional: false, scopes: ['standard', 'complete'] },
        ],
      },
      {
        id: 'bathroom',
        name: 'Bathroom',
        icon: 'shower',
        defaultIncluded: false,
        items: [
          { name: 'Vanity Unit', description: 'Bathroom vanity with sink and storage', pricingMethod: 'per_unit', defaultQuantity: 4, unit: 'unit', matchKeyword: 'Vanity', isOptional: false, scopes: ['complete'] },
          { name: 'Mirror Cabinet', description: '', pricingMethod: 'per_unit', defaultQuantity: 4, unit: 'unit', matchKeyword: 'Mirror Cabinet', isOptional: true, scopes: ['complete'] },
          { name: 'Shower Partition', description: '', pricingMethod: 'per_unit', defaultQuantity: 4, unit: 'unit', matchKeyword: 'Shower Partition', isOptional: true, scopes: ['complete'] },
        ],
      },
      {
        id: 'electrical',
        name: 'Electrical',
        icon: 'zap',
        defaultIncluded: false,
        items: [
          { name: 'Additional Light Points', description: '', pricingMethod: 'per_unit', defaultQuantity: 25, unit: 'unit', matchKeyword: 'Light Point', isOptional: false, scopes: ['complete'] },
          { name: 'Fan Points', description: '', pricingMethod: 'per_unit', defaultQuantity: 5, unit: 'unit', matchKeyword: 'Fan Point', isOptional: false, scopes: ['complete'] },
          { name: 'AC Points', description: '', pricingMethod: 'per_unit', defaultQuantity: 4, unit: 'unit', matchKeyword: 'AC Point', isOptional: false, scopes: ['complete'] },
          { name: 'TV Points', description: '', pricingMethod: 'per_unit', defaultQuantity: 4, unit: 'unit', matchKeyword: 'TV Point', isOptional: false, scopes: ['complete'] },
          { name: 'LED Strip Lighting', description: '', pricingMethod: 'per_unit', defaultQuantity: 12, unit: 'unit', matchKeyword: 'LED Strip', isOptional: true, scopes: ['complete'] },
          { name: 'Pendant Lighting', description: '', pricingMethod: 'per_unit', defaultQuantity: 5, unit: 'unit', matchKeyword: 'Pendant Light', isOptional: true, scopes: ['complete'] },
        ],
      },
      {
        id: 'painting',
        name: 'Painting / Wall Finishes',
        icon: 'paintbrush',
        defaultIncluded: false,
        items: [
          { name: 'Interior Painting', description: 'Premium emulsion paint for all walls', pricingMethod: 'per_sqft', defaultQuantity: 1000, unit: 'sq.ft', matchKeyword: 'Painting', isOptional: false, scopes: ['complete'] },
          { name: 'Wall Panelling', description: 'Decorative wall panel', pricingMethod: 'per_sqft', defaultQuantity: 120, unit: 'sq.ft', matchKeyword: 'Wall Panel', isOptional: true, scopes: ['complete'] },
          { name: 'Wallpaper', description: '', pricingMethod: 'per_sqft', defaultQuantity: 150, unit: 'sq.ft', matchKeyword: 'Wallpaper', isOptional: true, scopes: ['complete'] },
        ],
      },
    ],
  },
];

export const SCOPE_LEVELS: { id: ScopeLevel; name: string; description: string }[] = [
  { id: 'essential', name: 'Essential Interior', description: 'Kitchen + wardrobes + beds + basic TV unit' },
  { id: 'standard', name: 'Standard Interior', description: 'Essential + dressing + shoe rack + crockery + entrance + dining' },
  { id: 'complete', name: 'Complete Interior', description: 'Standard + false ceiling + electrical + painting + appliances + bathroom' },
];

export const KITCHEN_SHAPES: { id: KitchenShape; label: string; baseRft: number; wallRft: number }[] = [
  { id: 'L-shaped', label: 'L-Shaped', baseRft: 12, wallRft: 10 },
  { id: 'Straight', label: 'Straight', baseRft: 16, wallRft: 14 },
  { id: 'Parallel', label: 'Parallel', baseRft: 14, wallRft: 12 },
  { id: 'U-shaped', label: 'U-Shaped', baseRft: 18, wallRft: 14 },
  { id: 'Island', label: 'Island', baseRft: 18, wallRft: 12 },
  { id: 'Peninsula', label: 'Peninsula', baseRft: 16, wallRft: 10 },
];

export interface MaterialForMatching {
  id: string;
  name: string;
  category: string;
  unit: string;
  base_price: number;
  discount_price?: number | null;
  is_discounted?: boolean;
}

function computeAmount(width: number, height: number, depth: number, quantity: number, unitPrice: number, numberOfUnits: number, pricingMethod: PricingMethod): number {
  if (!unitPrice || unitPrice <= 0) return 0;
  const w = width > 0 ? width : 0;
  const h = height > 0 ? height : 0;
  const d = depth > 0 ? depth : 0;

  if (pricingMethod === 'per_sqft') {
    const area = w > 0 && h > 0 ? w * h : quantity;
    return area * (numberOfUnits || 1) * unitPrice;
  }
  if (pricingMethod === 'per_running_ft') {
    return quantity * (numberOfUnits || 1) * unitPrice;
  }
  return quantity * (numberOfUnits || 1) * unitPrice;
}

export function generateQuoteItemsFromTemplate(
  template: HomeTemplate,
  selectedRoomIds: string[],
  scope: ScopeLevel,
  kitchenShape: KitchenShape,
  materials: MaterialForMatching[],
): QuoteItem[] {
  const items: QuoteItem[] = [];
  const shapeConfig = KITCHEN_SHAPES.find(s => s.id === kitchenShape);

  for (const room of template.rooms) {
    if (!selectedRoomIds.includes(room.id)) continue;

    for (const tmplItem of room.items) {
      if (!tmplItem.scopes.includes(scope)) continue;

      let unitPrice = 0;
      let materialId: string | undefined;

      if (tmplItem.matchKeyword && materials.length > 0) {
        const match = bestMaterialMatch(tmplItem.matchKeyword, materials, 0.35);
        if (match) {
          materialId = match.id;
          unitPrice = match.is_discounted && match.discount_price != null
            ? match.discount_price
            : match.base_price;
        }
      }

      let quantity = tmplItem.defaultQuantity;
      let width = tmplItem.width;
      let height = tmplItem.height;
      let depth = tmplItem.depth;

      if (room.id === 'kitchen' && shapeConfig) {
        if (tmplItem.name === 'Base Cabinets') quantity = shapeConfig.baseRft;
        if (tmplItem.name === 'Wall Cabinets') quantity = shapeConfig.wallRft;
        if (tmplItem.name === 'Loft') quantity = shapeConfig.baseRft;
      }

      const numberOfUnits = tmplItem.pricingMethod === 'per_unit' ? tmplItem.defaultQuantity : 1;
      const effectiveQty = tmplItem.pricingMethod === 'per_unit' ? 1 : quantity;
      const amount = computeAmount(width || 0, height || 0, depth || 0, effectiveQty, unitPrice, numberOfUnits, tmplItem.pricingMethod);

      const roomLabel = room.name;
      const fullDescription = tmplItem.description
        ? `${tmplItem.description}`
        : '';

      items.push({
        item_type: 'other',
        name: tmplItem.name,
        description: fullDescription,
        number_of_units: numberOfUnits,
        quantity: effectiveQty,
        unit: tmplItem.unit,
        unit_price: unitPrice,
        discount_percent: 0,
        amount,
        section: roomLabel as any,
        pricing_mode: tmplItem.pricingMethod === 'per_sqft' ? 'modular' : 'standard',
        width: width,
        height: height,
        depth: depth,
        width_unit: tmplItem.widthUnit,
        height_unit: tmplItem.heightUnit,
        depth_unit: tmplItem.depthUnit,
        area_sqft: tmplItem.pricingMethod === 'per_sqft' && width && height ? parseFloat((width * height).toFixed(2)) : undefined,
        per_sqft_rate: tmplItem.pricingMethod === 'per_sqft' ? unitPrice : undefined,
        material_id: materialId,
      });
    }
  }

  return items;
}

export function getRoomsForTemplate(template: HomeTemplate, scope: ScopeLevel) {
  return template.rooms.map(room => {
    const visibleItems = room.items.filter(item => item.scopes.includes(scope));
    const includedItems = visibleItems.filter(item => !item.isOptional);
    return {
      id: room.id,
      name: room.name,
      icon: room.icon,
      defaultIncluded: room.defaultIncluded,
      totalItems: visibleItems.length,
      includedItems: includedItems.length,
      optionalItems: visibleItems.length - includedItems.length,
    };
  });
}

export function countItemsForSelection(
  template: HomeTemplate,
  selectedRoomIds: string[],
  scope: ScopeLevel,
): number {
  let count = 0;
  for (const room of template.rooms) {
    if (!selectedRoomIds.includes(room.id)) continue;
    count += room.items.filter(item => item.scopes.includes(scope)).length;
  }
  return count;
}

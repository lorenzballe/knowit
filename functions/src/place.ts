// Where a reader lives, and which cards belong there.
//
// The twin of lib/models/place.dart: the same shape, read from the same
// JSON, and the same fit, held to the same cases (tool/places/fit_cases.json)
// so that the phone and the server deal a card about Modena to the same
// readers. Only what the dealer needs is here; naming a region from what a
// phone says is the phone's work, done before anything reaches the server.

/** Where a reader is, as the phone keeps it and backs it up (`Place.toJson()`). */
export interface Place {
  /** ISO 3166-1 alpha-2, upper case: `IT`. */
  country: string;
  /** ISO 3166-2, where the app can name the region: `IT-45`. */
  region?: string;
  regionName?: string;
  city?: string;
  /** The point, rounded to a tenth of a degree on the phone. */
  lat?: number;
  lon?: number;
}

/** Where a card belongs, as its `place` says (tool/cards/schema.json). */
export interface CardPlace {
  country: string;
  region?: string;
  city?: string;
  lat?: number;
  lon?: number;
  km?: number;
}

/** How closely a card's place fits a reader's, nearest last so the order can be compared. */
export type PlaceFit = 'none' | 'country' | 'region' | 'city';

/** Nearest last: a city card beats a region card beats a country card. */
export const FIT_ORDER: readonly PlaceFit[] = ['none', 'country', 'region', 'city'];

/** How near a fit is, for sorting: 0 for none, 3 for the reader's city. */
export const fitRank = (fit: PlaceFit): number => FIT_ORDER.indexOf(fit);

function text(raw: Record<string, unknown>, key: string): string | undefined {
  const value = raw[key];
  return typeof value === 'string' && value.trim().length > 0 ? value : undefined;
}

function number(raw: Record<string, unknown>, key: string): number | undefined {
  const value = raw[key];
  return typeof value === 'number' && Number.isFinite(value) ? value : undefined;
}

/**
 * A reader's place as the backup holds it (`readers/{uid}.place`), or null
 * when there is none or it is not one: a country that is not two capital
 * letters is no place at all, as on the phone (`Place.fromJson`). A
 * malformed place deals nothing about any place, never something about the
 * wrong one.
 */
export function placeFromJson(raw: unknown): Place | null {
  if (typeof raw !== 'object' || raw === null || Array.isArray(raw)) return null;
  const r = raw as Record<string, unknown>;
  const country = r.country;
  if (typeof country !== 'string' || !/^[A-Z]{2}$/.test(country)) return null;
  return {
    country,
    region: text(r, 'region'),
    regionName: text(r, 'regionName'),
    city: text(r, 'city'),
    lat: number(r, 'lat'),
    lon: number(r, 'lon'),
  };
}

/** A card's place, or null when the card has none, or one the dealer cannot read, which then fits nobody. */
export function cardPlaceFromJson(raw: unknown): CardPlace | null {
  if (typeof raw !== 'object' || raw === null || Array.isArray(raw)) return null;
  const r = raw as Record<string, unknown>;
  const country = r.country;
  if (typeof country !== 'string' || country.length === 0) return null;
  const region = r.region;
  const city = r.city;
  return {
    country,
    region: typeof region === 'string' && region.length > 0 ? region : undefined,
    city: typeof city === 'string' && city.length > 0 ? city : undefined,
    lat: number(r, 'lat'),
    lon: number(r, 'lon'),
    km: number(r, 'km'),
  };
}

/**
 * How a card that belongs to [card] fits a reader who lives at [reader]
 * (`placeFit` in lib/models/place.dart):
 *
 * - a city card fits when the reader's point is within the card's `km` of
 *   the card's point, and never without both points: a card about a city
 *   is not dealt on a guess;
 * - a region card fits when the regions are the same;
 * - a country card fits anyone in the country.
 *
 * Nothing crosses a border.
 */
export function placeFit(card: CardPlace | null, reader: Place | null): PlaceFit {
  if (!card || !reader || card.country !== reader.country) return 'none';
  if (card.city !== undefined) {
    const { lat, lon, km } = card;
    if (lat === undefined || lon === undefined || km === undefined) return 'none';
    if (reader.lat === undefined || reader.lon === undefined) return 'none';
    return distanceKm(lat, lon, reader.lat, reader.lon) <= km ? 'city' : 'none';
  }
  if (card.region !== undefined) return card.region === reader.region ? 'region' : 'none';
  return 'country';
}

/** The distance along the ground between two points, in kilometres: the haversine, as on the phone. */
export function distanceKm(lat1: number, lon1: number, lat2: number, lon2: number): number {
  const earthKm = 6371.0;
  const rad = (degrees: number) => (degrees * Math.PI) / 180;
  const dLat = rad(lat2 - lat1);
  const dLon = rad(lon2 - lon1);
  const a = Math.sin(dLat / 2) ** 2 + Math.cos(rad(lat1)) * Math.cos(rad(lat2)) * Math.sin(dLon / 2) ** 2;
  return 2 * earthKm * Math.asin(Math.min(1, Math.sqrt(a)));
}

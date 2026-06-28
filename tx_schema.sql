-- ============================================================
-- TERRITORYX — SUPABASE DATABASE SCHEMA
-- Run this in Supabase SQL Editor → New Query → Run All
-- ============================================================

-- ── EXTENSIONS ──
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- ══════════════════════════════════════════
-- 1. PLATFORM CONFIG (admin key-value store)
-- ══════════════════════════════════════════
CREATE TABLE IF NOT EXISTS tx_config (
  key         TEXT PRIMARY KEY,
  value       TEXT NOT NULL DEFAULT '',
  label       TEXT NOT NULL DEFAULT '',
  description TEXT DEFAULT '',
  type        TEXT DEFAULT 'text',   -- text | number | boolean | textarea | color
  category    TEXT DEFAULT 'general' -- general | bidding | display | social
);

INSERT INTO tx_config (key, value, label, description, type, category) VALUES
  ('platform_name',        'TerritoryX',                            'Platform Name',              'Main brand name shown in header',               'text',    'general'),
  ('platform_tagline',     'Digital Billboard Real Estate — Southern Africa', 'Tagline',          'Sub-header tagline',                            'text',    'general'),
  ('platform_version',     'LITE V6.5',                             'Version Label',              'Badge shown top-left',                          'text',    'general'),
  ('admin_password',       'txadmin2025',                           'Admin Password',             'Password to access the admin panel',            'text',    'general'),
  ('contact_email',        '',                                      'Contact Email',              'Platform contact email',                        'text',    'general'),
  ('site_url',             'https://territoryx.co',                 'Site URL',                   'Public site URL',                               'text',    'general'),
  ('whatsapp_phone',       '27821234567',                           'WhatsApp Number',            'Operator WhatsApp (country code, no +)',         'text',    'social'),
  ('whatsapp_prefix',      'TERRITORYX OVERRIDE REQUEST',           'WhatsApp Message Prefix',    'First line of bid WhatsApp message',            'textarea','social'),
  ('currency_symbol',      'R',                                     'Currency Symbol',            'e.g. R, $, E',                                  'text',    'bidding'),
  ('currency_code',        'ZAR',                                   'Currency Code',              'ISO currency code',                             'text',    'bidding'),
  ('low_value_threshold',  '500',                                   'Low Value Threshold',        'Nodes below this use low increment',            'number',  'bidding'),
  ('min_increment_low',    '5',                                     'Min Increment (Low Nodes)',  'Minimum R increment for low-value nodes',       'number',  'bidding'),
  ('min_increment_high',   '50',                                    'Min Increment (High Nodes)', 'Minimum R increment for high-value nodes',      'number',  'bidding'),
  ('geolocation_enabled',  'true',                                  'Auto Geolocation',           'Auto-detect nearest node on load',              'boolean', 'display'),
  ('default_node_id',      'sandton-fd',                            'Default Node',               'Node shown if geolocation fails',               'text',    'display'),
  ('ticker_speed_seconds', '38',                                    'Ticker Speed (seconds)',     'Full scroll cycle in seconds',                  'number',  'display'),
  ('billboard_aspect',     '16/9',                                  'Billboard Aspect Ratio',     'CSS aspect-ratio value (e.g. 16/9)',            'text',    'display'),
  ('show_threat_bar',      'true',                                  'Show Threat Bar',            'Show vulnerability index on frontend',          'boolean', 'display'),
  ('show_challengers',     'true',                                  'Show Challengers',           'Show challenger list on frontend',              'boolean', 'display'),
  ('network_pulse_label',  'LIVE NODE MATCHING',                    'Network Pulse Label',        'Green status text in header',                   'text',    'display'),
  ('footer_text',          '© 2025 TerritoryX. All rights reserved.', 'Footer Text',             'Footer copyright text',                         'text',    'display')
ON CONFLICT (key) DO NOTHING;

-- ══════════════════════════════════════════
-- 2. CATEGORIES
-- ══════════════════════════════════════════
CREATE TABLE IF NOT EXISTS tx_categories (
  id         UUID    DEFAULT gen_random_uuid() PRIMARY KEY,
  name       TEXT    NOT NULL UNIQUE,   -- 'Urban Hub'
  slug       TEXT    NOT NULL UNIQUE,   -- 'urban-hub'
  label      TEXT    NOT NULL,          -- 'URBAN' (shown on filter button)
  sort_order INTEGER DEFAULT 0,
  is_active  BOOLEAN DEFAULT TRUE,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

INSERT INTO tx_categories (name, slug, label, sort_order) VALUES
  ('Urban Hub',       'urban-hub',       'URBAN',   1),
  ('Supermarket Hub', 'supermarket-hub', 'RETAIL',  2),
  ('Transport Hub',   'transport-hub',   'TRANSIT', 3),
  ('Airport Hub',     'airport-hub',     'AIRPORT', 4),
  ('Stadium Hub',     'stadium-hub',     'STADIUM', 5)
ON CONFLICT DO NOTHING;

-- ══════════════════════════════════════════
-- 3. PRESTIGE TIERS
-- ══════════════════════════════════════════
CREATE TABLE IF NOT EXISTS tx_prestige_tiers (
  id          UUID    DEFAULT gen_random_uuid() PRIMARY KEY,
  name        TEXT    NOT NULL UNIQUE,  -- 'LEGENDARY'
  color       TEXT    NOT NULL,         -- '#FF3D57' (text color)
  bg_color    TEXT    NOT NULL,         -- 'rgba(255,61,87,0.15)'
  border_color TEXT   NOT NULL,         -- 'rgba(255,61,87,0.25)'
  min_value   INTEGER DEFAULT 0,        -- auto-assign above this value
  sort_order  INTEGER DEFAULT 0,
  created_at  TIMESTAMPTZ DEFAULT NOW()
);

INSERT INTO tx_prestige_tiers (name, color, bg_color, border_color, min_value, sort_order) VALUES
  ('BRONZE',    '#CD7F32', 'rgba(205,127,50,0.12)',  'rgba(205,127,50,0.25)',  0,    1),
  ('SILVER',    '#94A3B8', 'rgba(148,163,184,0.10)', 'rgba(148,163,184,0.22)', 300,  2),
  ('GOLD',      '#FFC43D', 'rgba(255,196,61,0.12)',  'rgba(255,196,61,0.28)',  800,  3),
  ('PLATINUM',  '#00E5FF', 'rgba(0,229,255,0.10)',   'rgba(0,229,255,0.25)',   2000, 4),
  ('ELITE',     '#FFB800', 'rgba(255,184,0,0.15)',   'rgba(255,184,0,0.30)',   5000, 5),
  ('LEGENDARY', '#FF3D57', 'rgba(255,61,87,0.15)',   'rgba(255,61,87,0.25)',   8000, 6)
ON CONFLICT DO NOTHING;

-- ══════════════════════════════════════════
-- 4. NODES (billboard territories)
-- ══════════════════════════════════════════
CREATE TABLE IF NOT EXISTS tx_nodes (
  id               TEXT    PRIMARY KEY,  -- human slug: 'sandton-fd'
  name             TEXT    NOT NULL,
  sector           TEXT    NOT NULL,     -- 'GAUTENG // SOUTH AFRICA'
  country          TEXT    NOT NULL DEFAULT 'South Africa',
  city             TEXT    NOT NULL DEFAULT '',
  category_name    TEXT    NOT NULL DEFAULT 'Urban Hub',
  owner            TEXT    NOT NULL DEFAULT 'UNCLAIMED',
  value            INTEGER NOT NULL DEFAULT 0,
  prestige         TEXT    NOT NULL DEFAULT 'BRONZE',
  status           TEXT    NOT NULL DEFAULT 'AVAILABLE', -- AVAILABLE | FORTIFIED | TRENDING | UNDER ATTACK | HOT PROPERTY
  attention_index  NUMERIC(5,2)  DEFAULT 0,
  est_reach        TEXT    DEFAULT '0',
  engagement       TEXT    DEFAULT '0%',
  radius           TEXT    DEFAULT '0 km',
  threat           INTEGER DEFAULT 0 CHECK (threat >= 0 AND threat <= 100),
  image_url        TEXT    DEFAULT '',
  lat              NUMERIC(10,6),
  lng              NUMERIC(10,6),
  is_active        BOOLEAN DEFAULT TRUE,
  sort_order       INTEGER DEFAULT 0,
  notes            TEXT    DEFAULT '',   -- internal admin notes
  created_at       TIMESTAMPTZ DEFAULT NOW(),
  updated_at       TIMESTAMPTZ DEFAULT NOW()
);

-- Auto-update updated_at
CREATE OR REPLACE FUNCTION tx_set_updated_at()
RETURNS TRIGGER AS $$ BEGIN NEW.updated_at = NOW(); RETURN NEW; END; $$ LANGUAGE plpgsql;
CREATE TRIGGER tx_nodes_updated_at BEFORE UPDATE ON tx_nodes FOR EACH ROW EXECUTE FUNCTION tx_set_updated_at();

INSERT INTO tx_nodes (id, name, sector, country, city, category_name, owner, value, prestige, status, attention_index, est_reach, engagement, radius, threat, lat, lng, sort_order) VALUES
  ('sandton-fd',      'SANDTON FINANCIAL DISTRICT',     'GAUTENG // SOUTH AFRICA',      'South Africa', 'Johannesburg', 'Urban Hub',       'MTN TECH GLOBAL',   4500, 'LEGENDARY', 'FORTIFIED',    97.8, '1.4M',  '91%', '4.5 km', 12, -26.1044, 28.0526, 1),
  ('jhb-bridge',      'JOHANNESBURG CBD RAILWAY BRIDGE','GAUTENG // SOUTH AFRICA',      'South Africa', 'Johannesburg', 'Transport Hub',   'UNCLAIMED',         3200, 'GOLD',      'AVAILABLE',    88.4, '2.1M',  '85%', '3.0 km',  0, -26.2041, 28.0473, 2),
  ('mall-africa',     'MALL OF AFRICA — WATERFALL',     'GAUTENG // SOUTH AFRICA',      'South Africa', 'Johannesburg', 'Supermarket Hub', 'WOOLWORTHS RETAIL', 5800, 'LEGENDARY', 'FORTIFIED',    94.2, '3.2M',  '92%', '5.0 km', 18, -26.0147, 28.1071, 3),
  ('pretoria-union',  'UNION BUILDINGS PRECINCT',       'GAUTENG // SOUTH AFRICA',      'South Africa', 'Pretoria',     'Urban Hub',       'SASOL ENERGY',      4100, 'ELITE',     'TRENDING',     85.6, '980K',  '87%', '3.5 km', 42, -25.7405, 28.2122, 4),
  ('cpt-waterfront',  'V&A WATERFRONT — CAPE TOWN',     'WESTERN CAPE // SOUTH AFRICA', 'South Africa', 'Cape Town',    'Supermarket Hub', 'ABSA BANK',         7200, 'LEGENDARY', 'FORTIFIED',    98.1, '4.5M',  '94%', '6.0 km',  8, -33.9050, 18.4194, 5),
  ('shoprite-manzini','SHOPRITE MANZINI COMPLEX',       'MANZINI // ESWATINI',          'Eswatini',     'Manzini',      'Supermarket Hub', 'UNCLAIMED',          280, 'SILVER',    'AVAILABLE',    48.3, '95K',   '78%', '1.2 km',  0, -26.4918, 31.3711, 6),
  ('taxi-mbabane',    'MBABANE MAIN TAXI RANK',         'MBABANE // ESWATINI',          'Eswatini',     'Mbabane',      'Transport Hub',   'CONWAY PHARMACIES',  495, 'PLATINUM',  'UNDER ATTACK', 89.1, '450K',  '93%', '0.8 km', 94, -26.3194, 31.1369, 7),
  ('matsapha-ind',    'MATSAPHA INDUSTRIAL ZONE',       'MATSAPHA // ESWATINI',         'Eswatini',     'Matsapha',     'Urban Hub',       'TOYOTA NETWORK',     850, 'GOLD',      'TRENDING',     71.4, '310K',  '84%', '3.2 km', 68, -26.5122, 31.3189, 8),
  ('gables-ezulwini', 'THE GABLES SHOPPING CENTRE',     'EZULWINI VALLEY // ESWATINI',  'Eswatini',     'Ezulwini',     'Supermarket Hub', 'WOOLWORTHS RETAIL', 1200, 'ELITE',     'HOT PROPERTY', 82.5, '180K',  '88%', '2.5 km', 45, -26.4194, 31.1764, 9)
ON CONFLICT DO NOTHING;

-- ══════════════════════════════════════════
-- 5. CHALLENGERS
-- ══════════════════════════════════════════
CREATE TABLE IF NOT EXISTS tx_challengers (
  id          UUID    DEFAULT gen_random_uuid() PRIMARY KEY,
  node_id     TEXT    NOT NULL REFERENCES tx_nodes(id) ON DELETE CASCADE,
  brand_name  TEXT    NOT NULL,
  bid_amount  INTEGER,
  is_active   BOOLEAN DEFAULT TRUE,
  sort_order  INTEGER DEFAULT 0,
  created_at  TIMESTAMPTZ DEFAULT NOW()
);

INSERT INTO tx_challengers (node_id, brand_name, bid_amount, sort_order) VALUES
  ('sandton-fd',     'Vodacom Group',      4200, 1),
  ('sandton-fd',     'FNB Digital',        4100, 2),
  ('sandton-fd',     'Discovery Networks', 3900, 3),
  ('jhb-bridge',     'SAB Miller',         3100, 1),
  ('jhb-bridge',     'Standard Bank',      3050, 2),
  ('mall-africa',    'Edcon Group',        5600, 1),
  ('mall-africa',    'Pick n Pay',         5400, 2),
  ('pretoria-union', 'TotalEnergies SA',   3900, 1),
  ('pretoria-union', 'Engen Petroleum',    3800, 2),
  ('cpt-waterfront', 'Nedbank',            7000, 1),
  ('cpt-waterfront', 'Old Mutual',         6800, 2),
  ('taxi-mbabane',   'Swazi Commuter',      450, 1),
  ('taxi-mbabane',   'Build It Yard',       420, 2),
  ('matsapha-ind',   'Conco Swaziland',     800, 1),
  ('matsapha-ind',   'Logistics Unified',   780, 2),
  ('gables-ezulwini','Medsalv Pharmacy',   1150, 1),
  ('gables-ezulwini','Ezulwini Cinema',    1100, 2)
ON CONFLICT DO NOTHING;

-- ══════════════════════════════════════════
-- 6. BIDS (override requests from frontend)
-- ══════════════════════════════════════════
CREATE TABLE IF NOT EXISTS tx_bids (
  id               UUID    DEFAULT gen_random_uuid() PRIMARY KEY,
  node_id          TEXT    NOT NULL REFERENCES tx_nodes(id),
  node_name        TEXT    NOT NULL DEFAULT '',
  brand_name       TEXT    NOT NULL,
  contact_name     TEXT    NOT NULL,
  contact_phone    TEXT    NOT NULL,
  proposed_amount  INTEGER NOT NULL,
  current_value    INTEGER NOT NULL DEFAULT 0,
  status           TEXT    DEFAULT 'PENDING',  -- PENDING | APPROVED | REJECTED | INVOICED
  admin_notes      TEXT    DEFAULT '',
  source           TEXT    DEFAULT 'FRONTEND', -- FRONTEND | ADMIN | WHATSAPP
  created_at       TIMESTAMPTZ DEFAULT NOW(),
  updated_at       TIMESTAMPTZ DEFAULT NOW()
);
CREATE TRIGGER tx_bids_updated_at BEFORE UPDATE ON tx_bids FOR EACH ROW EXECUTE FUNCTION tx_set_updated_at();

-- ══════════════════════════════════════════
-- 7. TICKER MESSAGES
-- ══════════════════════════════════════════
CREATE TABLE IF NOT EXISTS tx_ticker (
  id         UUID    DEFAULT gen_random_uuid() PRIMARY KEY,
  message    TEXT    NOT NULL,
  color      TEXT    DEFAULT 'cyan',  -- cyan | gold | green | red | white
  is_active  BOOLEAN DEFAULT TRUE,
  sort_order INTEGER DEFAULT 0,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

INSERT INTO tx_ticker (message, color, sort_order) VALUES
  ('MTN DEFENDED SANDTON FINANCIAL DISTRICT — R4,500/MO',         'gold',  1),
  ('VODACOM INITIATED BID FOR CAPE TOWN WATERFRONT',              'white', 2),
  ('NEW: JOHANNESBURG CBD RAILWAY BRIDGE NOW AVAILABLE',          'green', 3),
  ('WOOLWORTHS SECURED MALL OF AFRICA — R5,800/MO',              'cyan',  4),
  ('HOT: DURBAN MARINE PARADE UNDER CONTEST — 55% THREAT',       'red',   5),
  ('AIR BOTSWANA FORTIFIED GABORONE AIRPORT GATEWAY',             'gold',  6),
  ('TOYOTA NETWORK CAPTURED MATSAPHA INDUSTRIAL ZONE',            'white', 7),
  ('SHOPRITE MANZINI COMPLEX OPEN — FIRST MOVER ADVANTAGE',      'green', 8)
ON CONFLICT DO NOTHING;

-- ══════════════════════════════════════════
-- 8. ROW LEVEL SECURITY
-- ══════════════════════════════════════════

-- Enable RLS
ALTER TABLE tx_config      ENABLE ROW LEVEL SECURITY;
ALTER TABLE tx_categories  ENABLE ROW LEVEL SECURITY;
ALTER TABLE tx_prestige_tiers ENABLE ROW LEVEL SECURITY;
ALTER TABLE tx_nodes       ENABLE ROW LEVEL SECURITY;
ALTER TABLE tx_challengers ENABLE ROW LEVEL SECURITY;
ALTER TABLE tx_bids        ENABLE ROW LEVEL SECURITY;
ALTER TABLE tx_ticker      ENABLE ROW LEVEL SECURITY;

-- Public can READ config, categories, tiers, active nodes, challengers, ticker
CREATE POLICY "Public read config"      ON tx_config          FOR SELECT USING (true);
CREATE POLICY "Public read categories"  ON tx_categories      FOR SELECT USING (is_active = true);
CREATE POLICY "Public read tiers"       ON tx_prestige_tiers  FOR SELECT USING (true);
CREATE POLICY "Public read nodes"       ON tx_nodes           FOR SELECT USING (is_active = true);
CREATE POLICY "Public read challengers" ON tx_challengers     FOR SELECT USING (is_active = true);
CREATE POLICY "Public read ticker"      ON tx_ticker          FOR SELECT USING (is_active = true);

-- Public can INSERT bids
CREATE POLICY "Public insert bids"      ON tx_bids            FOR INSERT WITH CHECK (true);

-- Service role (admin) has full access (bypasses RLS by default)

-- ══════════════════════════════════════════
-- 9. HELPER VIEWS
-- ══════════════════════════════════════════

-- Nodes with challenger array
CREATE OR REPLACE VIEW tx_nodes_full AS
SELECT 
  n.*,
  COALESCE(
    JSON_AGG(
      JSON_BUILD_OBJECT(
        'id',         c.id,
        'brand_name', c.brand_name,
        'bid_amount', c.bid_amount,
        'sort_order', c.sort_order
      ) ORDER BY c.sort_order
    ) FILTER (WHERE c.id IS NOT NULL AND c.is_active = true),
    '[]'::json
  ) AS challengers_json
FROM tx_nodes n
LEFT JOIN tx_challengers c ON c.node_id = n.id
WHERE n.is_active = true
GROUP BY n.id
ORDER BY n.sort_order, n.created_at;

-- Dashboard stats
CREATE OR REPLACE VIEW tx_dashboard_stats AS
SELECT
  (SELECT COUNT(*) FROM tx_nodes WHERE is_active=true)                       AS total_nodes,
  (SELECT COUNT(*) FROM tx_nodes WHERE owner='UNCLAIMED' AND is_active=true) AS available_nodes,
  (SELECT COUNT(*) FROM tx_nodes WHERE owner!='UNCLAIMED' AND is_active=true)AS claimed_nodes,
  (SELECT COALESCE(SUM(value),0) FROM tx_nodes WHERE owner!='UNCLAIMED' AND is_active=true) AS total_monthly_value,
  (SELECT COUNT(*) FROM tx_bids WHERE status='PENDING')                      AS pending_bids,
  (SELECT COUNT(*) FROM tx_bids)                                             AS total_bids,
  (SELECT COUNT(*) FROM tx_bids WHERE status='APPROVED')                     AS approved_bids,
  (SELECT COUNT(DISTINCT owner) FROM tx_nodes WHERE owner!='UNCLAIMED')      AS active_brands;


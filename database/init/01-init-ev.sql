-- Create n8n database
CREATE DATABASE n8n_db;

-- Grant permissions for n8n database
GRANT ALL PRIVILEGES ON DATABASE n8n_db TO ev_chatbot_user;

-- Switch to main EV charger database
\c ev_charger_chatbot_db;

-- Create tables for EV charger business
CREATE TABLE IF NOT EXISTS customers (
    id SERIAL PRIMARY KEY,
    name VARCHAR(255),
    email VARCHAR(255) UNIQUE,
    phone VARCHAR(50),
    company VARCHAR(255),
    preferred_language VARCHAR(20) DEFAULT 'english',
    whatsapp_id VARCHAR(255),
    location VARCHAR(255),
    installation_type VARCHAR(100), -- residential, commercial, public
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS ev_chargers (
    id SERIAL PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    category VARCHAR(100) NOT NULL, -- level1, level2, dc_fast, portable
    power_output VARCHAR(50), -- 3.7kW, 7kW, 22kW, 50kW, 150kW, etc.
    connector_type VARCHAR(100), -- Type1, Type2, CCS, CHAdeMO, Tesla
    price DECIMAL(10, 2) NOT NULL,
    installation_cost DECIMAL(10, 2) DEFAULT 0,
    description TEXT,
    features JSONB,
    suitable_for VARCHAR(100), -- residential, commercial, public
    brand VARCHAR(100),
    warranty_years INTEGER DEFAULT 2,
    active BOOLEAN DEFAULT true,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS ev_vehicles (
    id SERIAL PRIMARY KEY,
    make VARCHAR(100) NOT NULL,
    model VARCHAR(100) NOT NULL,
    year INTEGER,
    battery_capacity VARCHAR(50), -- 40kWh, 75kWh, etc.
    max_charging_speed VARCHAR(50), -- 7kW, 11kW, 150kW
    connector_types JSONB, -- ["Type2", "CCS"]
    range_km INTEGER,
    price DECIMAL(12, 2),
    category VARCHAR(50), -- sedan, suv, hatchback, commercial
    active BOOLEAN DEFAULT true,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS estimates (
    id SERIAL PRIMARY KEY,
    customer_id INTEGER REFERENCES customers(id),
    products JSONB, -- chargers and/or vehicles
    installation_requirements JSONB,
    subtotal DECIMAL(10, 2),
    installation_cost DECIMAL(10, 2) DEFAULT 0,
    permit_cost DECIMAL(10, 2) DEFAULT 0,
    discount_percentage DECIMAL(5, 2) DEFAULT 0,
    discount_amount DECIMAL(10, 2) DEFAULT 0,
    tax_percentage DECIMAL(5, 2) DEFAULT 10,
    tax_amount DECIMAL(10, 2) DEFAULT 0,
    total_amount DECIMAL(10, 2),
    status VARCHAR(50) DEFAULT 'draft',
    valid_until TIMESTAMP,
    notes TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS conversations (
    id SERIAL PRIMARY KEY,
    customer_id INTEGER REFERENCES customers(id),
    conversation_id VARCHAR(255) UNIQUE,
    platform VARCHAR(50) DEFAULT 'whatsapp',
    language VARCHAR(20) DEFAULT 'english',
    status VARCHAR(50) DEFAULT 'active',
    current_step VARCHAR(100),
    context JSONB,
    started_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    ended_at TIMESTAMP
);

CREATE TABLE IF NOT EXISTS leads (
    id SERIAL PRIMARY KEY,
    customer_id INTEGER REFERENCES customers(id),
    conversation_id VARCHAR(255),
    estimate_id INTEGER REFERENCES estimates(id),
    assigned_sales_rep VARCHAR(255) DEFAULT 'anasmis',
    status VARCHAR(50) DEFAULT 'new',
    priority VARCHAR(20) DEFAULT 'medium',
    lead_source VARCHAR(50) DEFAULT 'whatsapp_bot',
    notes TEXT,
    follow_up_date TIMESTAMP,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Insert EV Chargers
INSERT INTO ev_chargers (name, category, power_output, connector_type, price, installation_cost, description, features, suitable_for, brand, warranty_years) VALUES

-- Level 1 Chargers (Portable/Basic)
('EV Portable Charger 10A', 'level1', '2.3kW', 'Type1/Type2', 299.00, 0, 'Portable EV charger for emergency use, plugs into standard outlet', '{"portable": true, "weatherproof": "IP65", "cable_length": "5m"}', 'residential', 'ChargePoint', 2),

-- Level 2 Chargers (Home/Workplace)
('WallBox Pulsar Plus 7kW', 'level2', '7kW', 'Type2', 899.00, 500, 'Smart home EV charger with WiFi connectivity and mobile app', '{"smart": true, "wifi": true, "app_control": true, "scheduling": true}', 'residential', 'WallBox', 3),

('ChargePoint Home Flex 11kW', 'level2', '11kW', 'Type2', 1299.00, 750, 'Flexible home charging solution with adjustable power settings', '{"adjustable_power": true, "wifi": true, "load_balancing": true}', 'residential', 'ChargePoint', 3),

('ABB Terra AC 22kW', 'level2', '22kW', 'Type2', 2499.00, 1200, 'Commercial AC charger for workplace and public locations', '{"commercial_grade": true, "payment_system": true, "dual_outlet": true}', 'commercial', 'ABB', 5),

-- DC Fast Chargers
('ABB Terra 54 CJG', 'dc_fast', '50kW', 'CCS/CHAdeMO', 25000.00, 5000, 'DC fast charger for public and commercial use', '{"dual_standard": true, "payment_system": true, "remote_monitoring": true}', 'public', 'ABB', 5),

('Tesla Supercharger V3', 'dc_fast', '250kW', 'Tesla/CCS', 45000.00, 8000, 'Ultra-fast charging for Tesla and CCS vehicles', '{"ultra_fast": true, "liquid_cooled": true, "tesla_network": true}', 'public', 'Tesla', 4),

('Tritium Veefil-PK 175kW', 'dc_fast', '175kW', 'CCS/CHAdeMO', 35000.00, 6000, 'High-power DC fast charger with dual outlets', '{"high_power": true, "dual_outlet": true, "compact_design": true}', 'public', 'Tritium', 5),

-- Portable Solutions
('Juice Booster 2 Portable', 'portable', '22kW', 'Type2', 1099.00, 0, 'Ultra-portable charger that works with any outlet worldwide', '{"universal_adapters": true, "portable": true, "smart_features": true}', 'residential', 'Juice Technology', 3);

-- Insert Popular EV Vehicles
INSERT INTO ev_vehicles (make, model, year, battery_capacity, max_charging_speed, connector_types, range_km, price, category) VALUES

-- Tesla Models
('Tesla', 'Model 3 Standard Range', 2024, '60kWh', '170kW', '["Tesla Supercharger", "CCS2"]', 491, 42990.00, 'sedan'),
('Tesla', 'Model 3 Long Range', 2024, '82kWh', '250kW', '["Tesla Supercharger", "CCS2"]', 629, 50990.00, 'sedan'),
('Tesla', 'Model Y Long Range', 2024, '82kWh', '250kW', '["Tesla Supercharger", "CCS2"]', 533, 56990.00, 'suv'),
('Tesla', 'Model S', 2024, '100kWh', '250kW', '["Tesla Supercharger", "CCS2"]', 652, 94990.00, 'sedan'),

-- BMW Models
('BMW', 'iX3', 2024, '80kWh', '150kW', '["Type2", "CCS2"]', 460, 68900.00, 'suv'),
('BMW', 'i4 eDrive40', 2024, '84kWh', '200kW', '["Type2", "CCS2"]', 590, 69900.00, 'sedan'),
('BMW', 'iX xDrive50', 2024, '111kWh', '200kW', '["Type2", "CCS2"]', 630, 99900.00, 'suv'),

-- Volkswagen Group
('Volkswagen', 'ID.4 Pro', 2024, '82kWh', '135kW', '["Type2", "CCS2"]', 520, 52900.00, 'suv'),
('Audi', 'e-tron GT', 2024, '93kWh', '270kW', '["Type2", "CCS2"]', 487, 125900.00, 'sedan'),
('Porsche', 'Taycan 4S', 2024, '93kWh', '270kW', '["Type2", "CCS2"]', 463, 126900.00, 'sedan'),

-- Mercedes
('Mercedes-Benz', 'EQC 400', 2024, '80kWh', '110kW', '["Type2", "CCS2"]', 427, 79900.00, 'suv'),
('Mercedes-Benz', 'EQS 450+', 2024, '108kWh', '200kW', '["Type2", "CCS2"]', 770, 129900.00, 'sedan'),

-- Asian Brands
('Hyundai', 'IONIQ 5', 2024, '77kWh', '235kW', '["Type2", "CCS2"]', 481, 54900.00, 'suv'),
('Kia', 'EV6 GT-Line', 2024, '77kWh', '235kW', '["Type2", "CCS2"]', 528, 59900.00, 'suv'),
('Nissan', 'Leaf e+', 2024, '62kWh', '100kW', '["Type2", "CHAdeMO"]', 385, 44900.00, 'hatchback'),

-- Commercial Vehicles
('Mercedes-Benz', 'eSprinter', 2024, '113kWh', '115kW', '["Type2", "CCS2"]', 440, 79900.00, 'commercial'),
('Volkswagen', 'ID.Buzz Pro', 2024, '82kWh', '170kW', '["Type2", "CCS2"]', 423, 64900.00, 'commercial'),
('Ford', 'E-Transit', 2024, '68kWh', '115kW', '["Type2", "CCS2"]', 317, 59900.00, 'commercial');

-- Create indexes for performance
CREATE INDEX IF NOT EXISTS idx_customers_email ON customers(email);
CREATE INDEX IF NOT EXISTS idx_customers_whatsapp_id ON customers(whatsapp_id);
CREATE INDEX IF NOT EXISTS idx_customers_company ON customers(company);
CREATE INDEX IF NOT EXISTS idx_ev_chargers_category ON ev_chargers(category);
CREATE INDEX IF NOT EXISTS idx_ev_chargers_suitable_for ON ev_chargers(suitable_for);
CREATE INDEX IF NOT EXISTS idx_ev_vehicles_make ON ev_vehicles(make);
CREATE INDEX IF NOT EXISTS idx_ev_vehicles_category ON ev_vehicles(category);
CREATE INDEX IF NOT EXISTS idx_conversations_customer_id ON conversations(customer_id);
CREATE INDEX IF NOT EXISTS idx_estimates_customer_id ON estimates(customer_id);
CREATE INDEX IF NOT EXISTS idx_leads_assigned_sales_rep ON leads(assigned_sales_rep);
CREATE INDEX IF NOT EXISTS idx_leads_status ON leads(status);

-- Grant all permissions to EV chatbot user
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO ev_chatbot_user;
GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA public TO ev_chatbot_user;
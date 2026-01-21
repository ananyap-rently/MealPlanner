# GitHub Copilot Instructions

## Table of Contents
1. [Product Overview](#product-overview)
2. [General Principles](#general-principles)
3. [Chat Modes](#chat-modes)
4. [Backend Guidelines (Ruby on Rails)](#backend-guidelines-ruby-on-rails)
5. [Frontend Guidelines (JavaScript/jQuery)](#frontend-guidelines-javascriptjquery)
6. [Database Guidelines (PostgreSQL)](#database-guidelines-postgresql)
7. [Database Migrations](#database-migrations)
8. [Testing Guidelines (RSpec)](#testing-guidelines-rspec)
9. [Code Documentation Standards](#code-documentation-standards)
10. [Performance Guidelines](#performance-guidelines)
11. [Security Guidelines](#security-guidelines)
12. [Code Review Guidelines](#code-review-guidelines)

## Product Overview

The **Smart Homes Application** is a comprehensive property management and IoT platform that enables property managers, agents, and service providers to remotely manage residential properties through connected devices and automation systems.

### Core Business Value
- **Property Management**: Centralized control of multiple residential properties for property management companies
- **Remote Access Control**: Secure lock code management and device control for smarthome entry systems
- **Service Coordination**: Streamlined maintenance, cleaning, and inspection workflows
- **Resident Experience**: Enhanced resident experience through smart home automation and self-service capabilities

### Key Stakeholders
- **Property Managers**: Oversee multiple properties, manage resident access, coordinate services
- **Agents**: Handle day-to-day property operations, resident interactions, and service scheduling
- **Service Providers**: Leasing Specialist, Workers, Reservation
- **Residents**: End users benefiting from smart home features and streamlined services

### Primary Features
- **Lock Code Management**: Create, distribute, and manage temporary/permanent access codes for smart locks
- **Device Integration**: Connect and control comprehensive IoT devices across properties:
  - **Smart Locks**: smarthome entry systems with remote access control
  - **Hubs**: Central control units for property automation and device coordination
  - **Security Systems**: Motion sensors, contact sensors, smoke alarms, and sirens for property monitoring
  - **Climate Control**: Thermostats and HVAC systems for temperature management
  - **Lighting & Power**: Smart switches, dimmable switches, and lightbulbs for automated lighting control
  - **Doorbell Cameras**: Video doorbells with motion detection and remote monitoring capabilities
  - **Safety Devices**: Leakage sensors, valve controllers, and emergency notification systems
- **Work Order System**: Automated maintenance and service request management with smart scheduling
- **Property Dashboard**: Real-time visibility into property status, occupancy, and device health across all connected systems
- **Data-Driven Analytics & Business Intelligence**: Comprehensive reporting and analytics platform powered by:
  - **Microsoft Power BI Integration**: Interactive dashboards and embedded reports for data visualization
  - **HVAC Analytics**: Temperature monitoring, energy usage patterns, and climate control optimization
  - **Device Performance Metrics**: Real-time monitoring of device health, connectivity status, and usage patterns
  - **Real-Time Dashboard Statistics**: Live data feeds for immediate operational decision-making
- **Multi-Company Support**: Platform serves multiple property management companies with resident isolation

### Technical Architecture
- **Ruby on Rails API**: RESTful backend serving web and mobile clients
- **PostgreSQL Database**: Robust data storage with multi-tenancy support
- **AWS Cloud Infrastructure**: Comprehensive cloud-native architecture including:
  - **AWS IoT Core**: Device connectivity, shadow management, and real-time communication
  - **AWS SQS**: Message queuing for asynchronous processing and device event handling
  - **AWS SNS**: Push notification delivery and pub/sub messaging
  - **AWS Lambda**: Serverless functions for IoT processing, data transformation, and integrations
  - **AWS DynamoDB**: NoSQL database for activity logs, device telemetry, and real-time data
  - **AWS S3**: Object storage for device images, firmware updates, and data archival
  - **AWS CloudFront**: CDN for fast content delivery and device image hosting
  - **AWS Cognito**: Identity and access management for secure device authentication
- **Redis & Sidekiq**: Background job processing with Redis-backed queuing for asynchronous operations
- **Apache Kafka**: Event streaming platform for real-time data processing and analytics
  - **Kafka Sync**: Real-time device and data synchronization using Kafka producers
  - **Kafka Consumer**: Background consumers for processing device events and analytics streams
- **Armor**: Secure authentication and login management
- **Frontend Stack**:
  - **JavaScript & jQuery**: Interactive UI components, AJAX, and event handling
  - **HTML & CSS**: Responsive layouts and styling
  - **React**: Asset details page and advanced UI modules
- **Microsoft Power BI**: Business intelligence and data visualization integration

This platform transforms traditional property management by bringing smart home technology, automation, and centralized control to residential properties at scale.

## General Principles

### DRY (Don't Repeat Yourself)
- Extract common functionality into methods, modules, concerns, and helper methods
- Use shared examples in RSpec tests
- Create reusable JavaScript functions and modules
- Use CSS variables, mixins, and utility classes to avoid style repetition

### SOLID Principles
- **Single Responsibility**: Each class/method should have one reason to change
  - Controllers should only handle HTTP requests and delegate to services
  - Models should contain domain logic and data access for their specific entity
  - Services should handle specific business operations (e.g., LockCodeService only manages lock codes)
  - Workers should handle only background job processing
- **Open/Closed**: Open for extension, closed for modification
  - Use Rails concerns and modules for shared functionality
  - Extend behavior through inheritance and composition, not modification
- **Liskov Substitution**: Subtypes must be substitutable for their base types
  - All device types should respond to the same interface methods
  - Subclasses should not break parent class contracts
- **Interface Segregation**: Many client-specific interfaces are better than one general-purpose interface
  - Create specific service interfaces rather than monolithic services
  - Use role-based concerns instead of god-like modules
- **Dependency Inversion**: Depend on abstractions, not concretions
  - Inject dependencies rather than hard-coding them
  - Use Rails dependency injection patterns and service objects

### Git Workflow

**CRITICAL RESTRICTIONS:**
- **No Automatic Merging**: Copilot agents must NEVER merge any code changes to any branch automatically. All merges require human review and approval.

## Backend Guidelines (Ruby on Rails)

### Ruby Style & RuboCop/Pronto Compliance

Follow the project's `.rubocop.yml` configuration and Pronto setup. Key patterns for Copilot:

```ruby
# Method length: max 10 lines
def create_lock_code
  validate_params
  build_lock_code
  save_and_respond
end

# Trailing commas in multiline structures
lock_code_params = {
  name: params[:name],
  security_code: params[:security_code],
  validity_type: params[:validity_type],
}

# Class length: under 300 lines
# Line length: max 120 characters
# Use snake_case for variables/methods, PascalCase for classes
```

### MVC Architecture Standards

**Separation of Concerns:**
- **Controllers**: Handle HTTP requests, parameter validation, response formatting
- **Models**: Entity-specific domain logic, validations, associations, and simple business rules
- **Views**: Presentation logic, HTML structure, and user interface rendering
- **Helpers**: View-specific utility methods, formatting, and presentation logic
- **Services**: Complex business workflows, multi-entity orchestration, and cross-cutting concerns
- **Workers**: Background job processing, async operations, and scheduled tasks
- **Lib**: Shared utilities, external API integrations, and reusable business logic

#### Controllers
```ruby
# Good: Thin controllers
class LockCodesController < ApplicationController
  before_action :authenticate_agent!
  before_action :set_lock_code, only: [:show, :edit, :update, :destroy]

  def create
    @lock_code = LockCodeService.new(lock_code_params).call
    
    if @lock_code.persisted?
      render json: success_response(@lock_code)
    else
      render json: error_response(@lock_code.errors)
    end
  end

  private

  def lock_code_params
    params.require(:lock_code).permit(:name, :security_code, :validity_type)
  end

  def set_lock_code
    @lock_code = current_company.lock_codes.find(params[:id])
  end
end
```

**Private Methods in Controllers:**
- Private methods in controllers should only be used for internal logic, helpers, or parameter sanitization.
- Use private methods for code reuse, DRYness, and encapsulation of logic that supports actions (e.g., strong parameter filtering, record lookup, service delegation).
- Name private methods clearly to reflect their purpose (e.g., `set_lock_code`, `lock_code_params`).

#### Models
```ruby
# Good: Fat models with entity-specific business logic
# Models should contain domain logic related to their specific entity
# but delegate complex orchestration to services
class LockCode < ApplicationRecord
  include LockCodeValidations
  include LockCodeStateMachine

  belongs_to :company
  has_many :device_lockcodes, dependent: :destroy
  has_many :devices, through: :device_lockcodes

  validates :name, presence: true, length: { maximum: 255 }
  validates :security_code, presence: true, uniqueness: { scope: :company_id }

  enum code_type: {
    hub_lock_code: 1,
    staff_code: 2,
    reservation_code: 3,
    installer_code: 4
  }

  scope :active, -> { where(deleted_at: nil) }
  scope :expired, -> { where('to_time < ?', Time.current) }

  # Entity-specific business logic (keep in model)
  def expired?
    to_time.present? && to_time < Time.current
  end

  def activate!
    update!(status: :active, activated_at: Time.current)
    notify_devices_of_activation
  end

  # Complex orchestration (delegate to service)
  def create_with_device_sync(params)
    LockCodeService.new(params).call
  end

  private

  def notify_devices_of_activation
    LockCodes::ActivationWorker.perform_async(id)
  end
end
```

#### Services
```ruby
# Good: Service objects for complex business logic and orchestration
# Use services for multi-step workflows, cross-entity operations, and complex business rules
# Services coordinate between models and handle error management
class LockCodeService
  include Callable

  def initialize(params)
    @params = params
    @lock_code = nil
    @errors = []
  end

  def call
    validate_business_rules
    return error_result if @errors.any?

    create_lock_code
    sync_with_devices if @lock_code.persisted?

    @lock_code
  end

  private

  attr_reader :params, :lock_code, :errors

  def validate_business_rules
    # Complex validation logic that spans multiple entities
    @errors << 'Name is required' if params[:name].blank?
    @errors << 'Security code is required' if params[:security_code].blank?
    @errors << 'Security code already exists' if security_code_taken?
  end

  def create_lock_code
    @lock_code = LockCode.new(params)
    @lock_code.save
  end

  def sync_with_devices
    # Complex orchestration across multiple devices
    lock_code.devices.each do |device|
      DeviceSyncService.new(device, lock_code).sync!
    end
  end

  def security_code_taken?
    # Cross-entity validation
    LockCode.where(company_id: params[:company_id], security_code: params[:security_code]).exists?
  end

  # Error result wrapper
  def error_result
    FailureResult.new(@errors)
  end
end
```

#### Views
```ruby
# Good: Thin views with minimal logic, delegate complex operations to helpers
# Views should focus on presentation, not business logic

# app/views/lock_codes/index.html.erb
<div class="lock-codes-container">
  <div class="header">
    <h1><%= t('.title') %></h1>
    <%= link_to t('.new_lock_code'), new_lock_code_path, class: 'btn btn-primary' %>
  </div>

  <div class="lock-codes-table">
    <%= render partial: 'lock_code', collection: @lock_codes %>
  </div>

  <%= paginate @lock_codes %>
</div>

# app/views/lock_codes/_lock_code.html.erb
<div class="lock-code-row" data-lock-code-id="<%= lock_code.id %>">
  <div class="lock-code-info">
    <h3><%= link_to lock_code.name, lock_code_path(lock_code) %></h3>
    <p class="security-code"><%= lock_code.security_code %></p>
    <span class="status <%= lock_code.status %>"><%= t("lock_codes.status.#{lock_code.status}") %></span>
  </div>

  <div class="lock-code-actions">
    <%= link_to t('.edit'), edit_lock_code_path(lock_code), class: 'btn btn-secondary' %>
    <%= link_to t('.delete'), lock_code_path(lock_code),
                method: :delete,
                data: { confirm: t('.confirm_delete') },
                class: 'btn btn-danger' %>
  </div>
</div>
```

#### Helpers
```ruby
# Good: Extract complex view logic into helper methods
# Helpers should contain presentation logic and formatting functions

# CONTROLLER-SPECIFIC HELPERS
# app/helpers/lock_codes_helper.rb
module LockCodesHelper
  def lock_code_status_badge(lock_code)
    status_class = case lock_code.status
                   when 'active' then 'badge-success'
                   when 'inactive' then 'badge-secondary'
                   when 'expired' then 'badge-danger'
                   else 'badge-warning'
                   end
    content_tag :span, lock_code.status.humanize, class: "badge #{status_class}"
  end

  def format_security_code(code)
    code.to_s.scan(/.{1,2}/).join('-')
  end

  def lock_code_expiry_info(lock_code)
    if lock_code.expired?
      content_tag :span, 'Expired', class: 'text-danger'
    elsif lock_code.to_time.present?
      "Expires: #{lock_code.to_time.strftime('%b %d, %Y')}"
    else
      'Never expires'
    end
  end
end

# APPLICATION-WIDE HELPERS
# app/helpers/application_helper.rb
module ApplicationHelper
  def flash_messages
    flash.each do |type, message|
      concat content_tag(:div, message, class: "alert alert-#{flash_class(type)}")
    end
    nil
  end

  def nav_link_to(name, path, options = {})
    classes = ['nav-link']
    classes << 'active' if current_page?(path)
    classes << options.delete(:class)
    link_to name, path, options.merge(class: classes.compact.join(' '))
  end

  private

  def flash_class(type)
    { notice: 'success', alert: 'danger', error: 'danger' }.fetch(type.to_sym, 'info')
  end
end
```

#### Workers
```ruby
# Good: Background job processing with proper error handling and monitoring
# Use workers for async operations, scheduled tasks, and heavy processing

# BACKGROUND JOB EXAMPLE: Async processing
# app/workers/lock_codes/sync_devices_worker.rb
class LockCodes::SyncDevicesWorker
  include Sidekiq::Worker

  sidekiq_options queue: :critical, retry: 3, backtrace: true

  def perform(lock_code_id, force_update = false)
    lock_code = LockCode.find(lock_code_id)

    lock_code.devices.find_each do |device|
      next if !force_update && device_already_synced?(device, lock_code)
      sync_lock_code_to_device(device, lock_code)
    end
  rescue ActiveRecord::RecordNotFound => e
    Rails.logger.error "Lock code not found: #{e.message}"
  rescue StandardError => e
    Rails.logger.error "Device sync failed: #{e.message}"
    raise e
  end

  private

  def sync_lock_code_to_device(device, lock_code)
    device_api = DeviceApi.new(device)
    device_api.update_lock_code(lock_code)
    Rails.logger.info "Synced lock code #{lock_code.id} to device #{device.id}"
  rescue DeviceApi::ConnectionError => e
    device.mark_as_offline!
    Rails.logger.warn "Device #{device.id} is offline: #{e.message}"
  end

  def device_already_synced?(device, lock_code)
    device.device_lockcodes.where(lock_code: lock_code).exists?
  end
end

# SCHEDULED JOB EXAMPLE: Maintenance tasks
# app/workers/maintenance/cleanup_expired_codes_worker.rb
class Maintenance::CleanupExpiredCodesWorker
  include Sidekiq::Worker

  sidekiq_options queue: :maintenance, retry: false

  def perform
    expired_codes = LockCode.expired.where('updated_at < ?', 30.days.ago)

    expired_codes.find_each do |lock_code|
      cleanup_lock_code(lock_code)
    end

    Rails.logger.info "Cleaned up #{expired_codes.count} expired lock codes"
  end

  private

  def cleanup_lock_code(lock_code)
    lock_code.devices.each do |device|
      DeviceApi.new(device).remove_lock_code(lock_code)
    end
    lock_code.update(deleted_at: Time.current)
  rescue StandardError => e
    Rails.logger.error "Failed to cleanup lock code #{lock_code.id}: #{e.message}"
  end
end
```

#### Lib
```ruby
# Good: Shared utilities and external API integrations
# Use lib for reusable business logic that doesn't fit in models/services
# Lib files can contain both CLASSES (for complex functionality) and MODULES (for mixins/utilities)

# CLASS EXAMPLE: External API integration
# lib/device_api.rb
class DeviceApi
  include HTTParty
  base_uri ENV.fetch('DEVICE_API_BASE_URL')

  def initialize(device)
    @device = device
    @auth_token = generate_auth_token
  end

  def update_lock_code(lock_code)
    response = self.class.post(
      "/devices/#{@device.external_id}/lock_codes",
      body: lock_code_payload(lock_code),
      headers: auth_headers
    )
    handle_response(response)
  end

  private

  def lock_code_payload(lock_code)
    { name: lock_code.name, code: lock_code.security_code }.to_json
  end

  def auth_headers
    { 'Authorization' => "Bearer #{@auth_token}", 'Content-Type' => 'application/json' }
  end

  def generate_auth_token
    JWT.encode({ device_id: @device.external_id, exp: 1.hour.from_now.to_i },
               ENV.fetch('DEVICE_API_SECRET'), 'HS256')
  end

  def handle_response(response)
    case response.code
    when 200..299 then JSON.parse(response.body)
    when 401 then raise AuthenticationError, "Device authentication failed"
    when 404 then raise ConnectionError, "Device not found"
    else raise ConnectionError, "Device API error: #{response.code}"
    end
  end
end

# MODULE EXAMPLE: Mixin for shared functionality
# lib/device_syncable.rb
module DeviceSyncable
  extend ActiveSupport::Concern

  included do
    after_save :sync_to_devices
    after_destroy :remove_from_devices
  end

  def sync_to_devices
    devices.each { |device| DeviceSyncJob.perform_later(self, device, :create) }
  end

  def remove_from_devices
    devices.each { |device| DeviceSyncJob.perform_later(self, device, :destroy) }
  end

  module ClassMethods
    def sync_all_to_device(device)
      find_each { |record| DeviceSyncJob.perform_later(record, device, :create) }
    end
  end
end

# Usage: class LockCode < ApplicationRecord; include DeviceSyncable; end
```

### Naming Conventions

```ruby
# Variables and methods: snake_case
user_name = "John Doe"
def calculate_total_amount; end

# Constants: SCREAMING_SNAKE_CASE
MAX_RETRY_ATTEMPTS = 3
DEFAULT_TIMEOUT = 30.seconds

# Classes and modules: PascalCase
class LockCodeManager; end
module DeviceIntegration; end

# Files: snake_case
# lock_code_service.rb
# device_integration_concern.rb
```

### Error Handling

```ruby
# Good: Specific error handling
begin
  device.update_lock_code(code)
rescue Device::ConnectionError => e
  Rails.logger.error "Device connection failed: #{e.message}"
  notify_support_team(e)
  raise ServiceError.new("Unable to connect to device")
rescue Device::AuthenticationError => e
  Rails.logger.error "Device authentication failed: #{e.message}"
  device.mark_as_unauthorized!
  raise ServiceError.new("Device authentication failed")
end

# Good: Custom error classes
class ServiceError < StandardError; end
class Device::ConnectionError < ServiceError; end
class Device::AuthenticationError < ServiceError; end
```

#### Exception Reporting (Airbrake)

Use `Airbrake.notify` to report unexpected exceptions and important non-exception events that need centralized visibility. This complements local logging (`Rails.logger`) and should never silently swallow errors.

**Core Principles:**
- Only notify Airbrake for exceptions that are truly unexpected or require monitoring; avoid spamming for validation failures or user input errors already surfaced to clients.
- Never include PII or secrets (passwords, access tokens, full addresses, emails unless essential). Scrub sensitive fields before sending.
- Provide a minimal context hash (IDs, environment, feature flags) alongside the exception to support quick sorting, grouping, and root cause analysis.
- Prefer notifying in service objects, workers, and boundary layers (external API integrations) rather than deep model methods unless the error is model-specific.

**Recommended Usage Pattern:**
```ruby
def perform_sync(device, lock_code)
  DeviceApi.new(device).update_lock_code(lock_code)
rescue DeviceApi::ConnectionError => e
  Airbrake.notify(e, {
    component: 'DeviceSyncService',
    device_id: device.id,
    device_external_id: device.external_id,
    lock_code_id: lock_code.id,
    company_id: lock_code.company_id,
    retry_count: (device.sync_attempts || 0),
  })
  device.mark_as_offline!
  raise ServiceError, 'Device connection failed'
end
```

**Workers:**
Report the failure once, then let Sidekiq retries handle subsequent attempts.
```ruby
class LockCodes::SyncDevicesWorker
  include Sidekiq::Worker
  sidekiq_options queue: :critical, retry: 3

  def perform(lock_code_id)
    lock_code = LockCode.find(lock_code_id)
    lock_code.devices.find_each do |device|
      sync_device(device, lock_code)
    end
  rescue ActiveRecord::RecordNotFound => e
    Airbrake.notify(e, { component: 'SyncDevicesWorker', lock_code_id: lock_code_id })
    Rails.logger.error "LockCode #{lock_code_id} missing"
  rescue StandardError => e
    Airbrake.notify(e, { component: 'SyncDevicesWorker', lock_code_id: lock_code_id })
    raise e # allow Sidekiq retry/backoff
  end

  private

  def sync_device(device, lock_code)
    DeviceApi.new(device).update_lock_code(lock_code)
  rescue DeviceApi::ConnectionError => e
    Airbrake.notify(e, { component: 'SyncDevicesWorker', device_id: device.id, lock_code_id: lock_code.id })
    device.mark_as_offline!
  end
end
```

**Controllers:**
Only notify Airbrake for unexpected infrastructure / integration failures or inconsistent state that cannot be resolved locally. Do not notify for standard validation errors or authorization denials already communicated to the client.
```ruby
class HubsController < ApplicationController
  # Example: transactional update with external device syncing and structured Airbrake context.
  def default_lock_update
    ActiveRecord::Base.transaction { update_default_lock }
    render json: { success: true, message: 'Default lock updated successfully.' }
  rescue StandardError => e
    Airbrake.notify(
      e,
      {
        component: 'HubsController',
        action: 'default_lock_update',
        hub_id: @hub.id,
        device_id: @device.id,
        device_type: @device.class.name,
        environment: Rails.env,
      },
    )
    render json: { success: false, message: 'Unexpected error. Retry later.' }, status: :internal_server_error
  end
end
```

Guidelines for controller Airbrake usage:
- Notify only for system/integration exceptions, not business validation.
- Include `component`, `action`, and primary entity ID(s) when available.
- Avoid leaking raw params; whitelist IDs and safe strings only.

**Concerns / Shared Modules:**
Concerns should generally delegate error reporting upward unless they are a boundary (e.g., integrating with external APIs). If a concern encapsulates cross-cutting logic hitting external services, centralize Airbrake notifying with sanitized context.
```ruby
module ExternalSyncable
  extend ActiveSupport::Concern

  included do
    after_commit :enqueue_sync, on: :create
  end

  def enqueue_sync
    ExternalSyncWorker.perform_async(self.class.name, id)
  rescue Redis::BaseError => e
    Airbrake.notify(
      e,
      {
        component: 'ExternalSyncable',
        record_class: self.class.name,
        record_id: id,
        environment: Rails.env,
        callback: 'enqueue_sync',
      },
    )
    Rails.logger.warn "Failed to enqueue sync for #{self.class.name}##{id}"
  end

  def safely_update_remote(remote_client)
    remote_client.push!(remote_payload)
  rescue remote_client.class::AuthError => e
    Airbrake.notify(e, {
      component: 'ExternalSyncable',
      record_class: self.class.name,
      record_id: id,
      environment: Rails.env,
      error_type: 'auth',
    })
    raise ServiceError, 'Remote authentication failed'
  rescue StandardError => e
    Airbrake.notify(e, {
      component: 'ExternalSyncable',
      record_class: self.class.name,
      record_id: id,
      environment: Rails.env,
    })
    raise
  end

  private

  def remote_payload
    { name: respond_to?(:name) ? name : self.class.name } # keep small
  end
end
```

Guidelines for concerns:
- Prefer letting callers (services/controllers) notify unless the concern owns the external boundary.
- Include minimal record identity (`record_class`, `record_id`).

**Avoid:**
- `Airbrake.notify` inside every small rescue leading to noise.
- Swallowing exception after notify without logging or re-raising when state is inconsistent.
- Sending large ActiveRecord objects directly (pass IDs, not entire records) to reduce payload size.

**Checklist Before Adding Airbrake.notify:**
- Is the event exceptional or critical for operations?
- Will context provided allow quick triage?
- Are sensitive fields excluded?
- Is duplicate reporting prevented?

### Code Reuse and Existing Method Verification

#### Check for Existing Methods Before Creating New Ones

**CRITICAL RULE**: Before implementing any new method, service, helper, or functionality, you must always check if similar functionality already exists in the codebase. This prevents code duplication and maintains consistency.

#### Pre-Implementation Checklist:
```ruby
# 1. Search for existing methods with similar functionality
# 2. Check if the use case is already covered by existing code
# 3. Reuse and extend existing methods when possible
# 4. Only create new methods when existing ones cannot be adapted
```

#### How to Check for Existing Methods:

**Use semantic search and grep to find existing functionality:**

1. **Semantic Search**: Use natural language to find related functionality
   - Search for: "authentication", "user validation", "lock code creation"
   - Look in: models, services, helpers, concerns, lib files

2. **Grep Search**: Search for specific method patterns
   - Search for method names: `def authenticate`, `def validate_`, `def create_`
   - Search for class patterns: `class.*Service`, `module.*Helper`

3. **File Structure Analysis**: Check relevant directories
   - `app/services/` - Business logic services
   - `app/helpers/` - View helpers and utilities
   - `lib/` - Shared utilities and external integrations
   - `app/concerns/` - Shared modules and concerns

#### Benefits of This Approach:

- **Consistency**: Maintains uniform code patterns across the application
- **Maintainability**: Reduces the number of methods to maintain
- **Testing**: Leverages existing test coverage
- **Performance**: Avoids duplicate code that increases bundle size
- **Standards**: Ensures adherence to established project patterns

#### When to Create New Methods:

Create new methods only when:
- No similar functionality exists after thorough search
- Existing methods cannot be reasonably extended or modified
- The new functionality requires significantly different approach
- Existing code would become overly complex if modified

**Remember**: Always prefer composition and extension over duplication.


## Frontend Guidelines (JavaScript/jQuery)

### ESLint Standards & Code Style
**Key Configuration File: `.eslintrc.js` - Contains the actual ESLint rules and settings for this project.**
```javascript
// Good: Consistent naming conventions
const deviceManager = new DeviceManager();
const lockCodeData = fetchLockCodeData();

// Functions: camelCase
function calculateExpiryTime(startTime, duration) {
  return new Date(startTime.getTime() + duration);
}

// Constants: SCREAMING_SNAKE_CASE
const MAX_RETRY_ATTEMPTS = 3;
const API_ENDPOINTS = {
  LOCK_CODES: '/api/lock_codes',
  DEVICES: '/api/devices',
};

// Good: Arrow functions for short operations
const filterActiveCodes = codes => codes.filter(code => code.status === 'active');

// Good: Proper jQuery usage
$(document).ready(() => {
  initializeLockCodeTable();
  bindEventHandlers();
});

function initializeLockCodeTable() {
  $('#lock-codes-table').DataTable({
    processing: true,
    serverSide: true,
    ajax: API_ENDPOINTS.LOCK_CODES,
    columns: [
      { data: 'name', orderable: true },
      { data: 'security_code', orderable: false },
      { data: 'status', orderable: true },
    ],
  });
}

// ESLint Rule Examples - Key Rules for Consistent Code
**Key ESLint Rules Summary** (see `.eslintrc.js` for complete configuration):
- `no-unused-vars`, `no-undef`: Prevent undefined variables
- `eqeqeq`: Use strict equality (`===` instead of `==`)
- `semi`, `quotes`: Consistent semicolons and single quotes
- `indent`: 2-space indentation
- `max-len`: 120 character line limit
- `camelcase`: camelCase for variables/functions
- `no-var`, `prefer-const`: Modern variable declarations
- `arrow-parens`: Parentheses around arrow function parameters
- `object-curly-spacing`, `array-bracket-spacing`: Consistent spacing
- `comma-dangle`: Trailing commas in multiline structures
- `prefer-template`: Template literals over string concatenation
- `curly`: Required curly braces for control statements
- `space-infix-ops`: Spacing around operators
```

### Event Handling

```javascript
// Good: Delegated event handling
$(document).on('click', '.lock-code-activate', function(e) {
  const lockCodeId = $(this).data('lock-code-id');
  activateLockCode(lockCodeId);
});

// Good: Debounced input handling
const debouncedSearch = debounce((query) => {
  searchLockCodes(query);
}, 300);

$('#lock-code-search').on('input', function() {
  const query = $(this).val();
  debouncedSearch(query);
});
```

### AJAX and API Calls

```javascript
// Good: Centralized API handling
class ApiClient {
  static async post(url, data) {
    try {
      const response = await $.ajax({
        url,
        method: 'POST',
        data: JSON.stringify(data),
        contentType: 'application/json',
        headers: {
          'X-CSRF-Token': $('meta[name="csrf-token"]').attr('content'),
        },
      });
      return { success: true, data: response };
    } catch (error) {
      console.error('API Error:', error);
      return { success: false, error: error.responseJSON || error };
    }
  }
}

// Usage
async function createLockCode(lockCodeData) {
  const result = await ApiClient.post('/api/lock_codes', lockCodeData);
  
  if (result.success) {
    showSuccessMessage('Lock code created successfully');
    refreshLockCodeTable();
  } else {
    showErrorMessage(result.error.message || 'Failed to create lock code');
  }
}
```

### Code Organization Patterns

**Choose the appropriate pattern based on your needs:**

#### ES6 Modules (Recommended for modern applications)
```javascript
// lib/api/lockCodeApi.js
export class LockCodeApi {
  static async create(data) {
    // Implementation
  }

  static async update(id, data) {
    // Implementation
  }
}

// Usage in another file
import { LockCodeApi } from './lib/api/lockCodeApi.js';

async function handleCreate() {
  const result = await LockCodeApi.create(lockCodeData);
}
```

#### Class-Based Organization
```javascript
// Recommended for complex state management
class LockCodeManager {
  constructor(containerId) {
    this.container = $(containerId);
    this.activeCodes = [];
  }

  async initialize() {
    await this.loadData();
    this.bindEvents();
  }

  async createLockCode(data) {
    // Implementation
  }
}

// Usage
const manager = new LockCodeManager('#lock-codes-container');
manager.initialize();
```

#### Traditional Module Pattern (Use when ES6 modules aren't available)
```javascript
// For legacy code or specific environments
const LockCodeManager = (function() {
  let activeCodes = [];
  let selectedDevices = [];

  function validateLockCode(code) {
    return code.name && code.security_code && code.security_code.length >= 4;
  }

  return {
    init() {
      bindEvents();
      loadInitialData();
    },

    addCode(codeData) {
      if (!validateLockCode(codeData)) {
        throw new Error('Invalid lock code data');
      }
      // Implementation
    },

    getActiveCodes() {
      return [...activeCodes];
    },
  };
})();
```

## Database Guidelines (PostgreSQL)

### Query Optimization

```ruby
# Good: Avoid N+1 queries
lock_codes = company.lock_codes.includes(:devices, :device_lockcodes)

# Good: Use specific indexes
class AddIndexToLockCodes < ActiveRecord::Migration[7.0]
  def change
    add_index :lock_codes, [:company_id, :status]
    add_index :lock_codes, [:security_code, :company_id], unique: true
    add_index :device_lockcodes, [:lock_code_id, :device_id]
  end
end

# Good: Efficient counting
Company.joins(:lock_codes).group(:id).count # Instead of company.lock_codes.count for each

# Good: Use database-level constraints
validates :security_code, uniqueness: { scope: [:company_id, :property_id] }

# Database migration
add_index :lock_codes, [:security_code, :company_id, :property_id], 
          unique: true, 
          name: 'unique_security_code_per_company_property'
```

### Data Integrity

```ruby
# Good: Use foreign key constraints
class CreateDeviceLockcodes < ActiveRecord::Migration[7.0]
  def change
    create_table :device_lockcodes do |t|
      t.references :lock_code, null: false, foreign_key: true
      t.references :device, null: false, foreign_key: true
      t.string :security_code, null: false
      t.integer :status, default: 0
      t.timestamps
    end

    add_index :device_lockcodes, [:lock_code_id, :device_id], unique: true
  end
end
```

## Database Migrations

### Migration File Naming & Structure
```bash
rails generate migration AddFieldToTableName
# Creates: YYYYMMDDHHMMSS_add_field_to_table_name.rb
```

**Use ARM_CLASS (ActiveRecord::Migration[7.0]):**
```ruby
class AddFieldToTableName < ARM_CLASS
  def change; end  # Simple migrations
end

class ComplexMigration < ARM_CLASS
  def up; end      # Complex migrations
  def down; end
end
```

### Common Migration Patterns

#### Creating Tables
```ruby
class CreateNewTable < ARM_CLASS
  def change
    create_table :new_table do |t|
      t.string :name, null: false
      t.integer :status, default: 0
      t.references :company, null: false, foreign_key: true
      t.timestamps null: false
    end
    add_index :new_table, [:company_id, :name], unique: true
  end
end
```

#### Adding Columns
```ruby
class AddFieldsToExistingTable < ARM_CLASS
  def change
    add_column :existing_table, :new_field, :string
    add_column :existing_table, :another_field, :integer, default: 0
    add_column :existing_table, :json_data, :jsonb, default: {}
  end
end
```

#### Adding Indexes
```ruby
class AddIndexesToTable < ARM_CLASS
  def change
    add_index :table_name, :field_name
    add_index :table_name, [:field1, :field2], unique: true
    add_index :table_name, :json_field, using: :gin  # JSONB fields
  end
end
```

#### Adding Foreign Keys
```ruby
class AddForeignKeys < ARM_CLASS
  def change
    add_foreign_key :child_table, :parent_table, on_delete: :cascade
    add_foreign_key :child_table, :parent_table, column: :custom_parent_id
  end
end
```

#### Data Migrations
```ruby
class MigrateExistingData < ARM_CLASS
  def change
    execute "DELETE FROM child_table WHERE parent_id NOT IN (SELECT id FROM parent_table)"
    execute "UPDATE table_name SET status = 1 WHERE status IS NULL"
    add_foreign_key :child_table, :parent_table
  end
end
```

#### UUID Primary Key Migration
```ruby
class ChangePrimaryKeyToUuid < ARM_CLASS
  def change
    add_column :table_name, :uuid, :uuid, default: 'uuid_generate_v4()', null: false
    execute "UPDATE table_name SET uuid = uuid_generate_v4() WHERE uuid IS NULL"
    execute "ALTER TABLE table_name DROP CONSTRAINT table_name_pkey"
    execute "ALTER TABLE table_name ADD PRIMARY KEY (uuid)"
    execute "ALTER TABLE table_name DROP COLUMN id CASCADE"
    execute "ALTER TABLE table_name RENAME COLUMN uuid TO id"
  end
end
```

### Migration Best Practices

#### Pre-generation Existence Checks

Before generating any migration that adds columns, indexes, foreign keys, or tables, Copilot must first verify whether the target object already exists. Perform a quick check by inspecting `db/structure.sql` (or `schema.rb` if present), grepping for the column/index name, or assuming runtime guards using Rails helpers. All additive migration statements must be wrapped in conditional guards using `unless column_exists?` / `unless index_exists?` / `unless foreign_key_exists?` / `unless table_exists?` to ensure idempotency and prevent failures when the field already exists due to parallel development or repeated CI runs.

```ruby
class AddFooBarToWidgets < ActiveRecord::Migration[7.0]
  def change
    unless table_exists?(:widgets)
      create_table :widgets do |t|
        t.string :name
        t.timestamps
      end
    end

    unless column_exists?(:widgets, :foo_bar)
      add_column :widgets, :foo_bar, :string
    end

    unless index_exists?(:widgets, :foo_bar)
      add_index :widgets, :foo_bar
    end
  end
end
```

Use these guards in newly generated migrations instead of blindly adding objects. This instruction enforces safe, re-runnable migrations and aligns with the existing "Safe Column Addition" and "Safe Index Addition" patterns further below.

#### Testing Migrations
```ruby
rails db:migrate    # Test forward
rails db:rollback   # Test rollback
rails db:migrate:redo # Test on development data
```

#### Large Table Operations
```ruby
class AddIndexToLargeTable < ARM_CLASS
  disable_ddl_transaction!
  
  def change
    original_timeout = ActiveRecord::Base.connection.execute('SHOW statement_timeout').first['statement_timeout']
    ActiveRecord::Base.connection.execute('set statement_timeout to 360000') # 6 min
    
    add_index :large_table, :field_name, algorithm: :concurrently
    
    ActiveRecord::Base.connection.execute("SET statement_timeout = '#{original_timeout}'")
  end
end
```

#### Large Tables with Extensions
```ruby
class AddComplexIndexToLargeTable < ARM_CLASS
  disable_ddl_transaction!
  
  def change
    original_timeout = ActiveRecord::Base.connection.execute('SHOW statement_timeout').first['statement_timeout']
    ActiveRecord::Base.connection.execute('set statement_timeout to 360000')
    
    enable_extension 'pg_trgm' unless extension_enabled?('pg_trgm')
    
    add_index :properties, [:external_company_id, :city, :state, :zipcode, :unit_number, :community_id],
              algorithm: :concurrently, where: 'deleted_at IS NULL',
              name: 'index_properties_on_external_company_id_and_address_components'
    
    add_index :properties, :street_address, using: :gin, opclass: :gin_trgm_ops,
              algorithm: :concurrently, where: 'deleted_at IS NULL',
              name: 'index_properties_on_street_address_trgm'
    
    ActiveRecord::Base.connection.execute("SET statement_timeout = '#{original_timeout}'")
  end
end
```

#### Proper Data Types
```ruby
class UseAppropriateDataTypes < ARM_CLASS
  def change
    add_column :table, :email, :string
    add_column :table, :price, :decimal, precision: 10, scale: 2
    add_column :table, :metadata, :jsonb
    add_column :table, :tags, :string, array: true, default: []
    add_column :table, :occurred_at, :timestamp
  end
end
```

#### Rollback Safety
```ruby
class SafeMigrationWithRollback < ARM_CLASS
  def change
    add_column :table, :new_column, :string
    
    reversible do |dir|
      dir.up do
        execute "UPDATE table SET new_column = 'default_value' WHERE new_column IS NULL"
      end
      
      dir.down do
        execute "UPDATE table SET new_column = NULL"
      end
    end
  end
end
```

#### Safe Column Addition
```ruby
class AddColumnSafely < ARM_CLASS
  def change
    unless column_exists?(:table_name, :column_name)
      original_timeout = ActiveRecord::Base.connection.execute('SHOW statement_timeout').first['statement_timeout']
      ActiveRecord::Base.connection.execute('set statement_timeout to 120000') # 2 min
      
      add_column :table_name, :column_name, :boolean, default: false
      
      ActiveRecord::Base.connection.execute("SET statement_timeout = '#{original_timeout}'")
    end
  end
end
```

#### Safe Index Addition
```ruby
class AddIndexSafely < ARM_CLASS
  def change
    unless index_exists?(:table_name, :column_name)
      add_index :table_name, :column_name
    end
    
    unless index_exists?(:table_name, :index_name)
      add_index :table_name, [:column1, :column2], name: :index_name
    end
  end
end
```

#### Migration Dependencies
```ruby
class MigrationWithDependencies < ARM_CLASS
  def change
    execute <<-SQL
      CREATE OR REPLACE FUNCTION update_updated_at_column()
      RETURNS TRIGGER AS $$
      BEGIN
          NEW.updated_at = NOW();
          RETURN NEW;
      END;
      $$ language 'plpgsql';
    SQL
  end
end
```

## Testing Guidelines (RSpec)

### BetterSpecs Standards & Code Style
**Guidelines Document**: `.betterspecs.yml` - This YAML file contains comprehensive BetterSpecs guidelines and patterns for this project.
```yaml
# Core Principles from .betterspecs.yml
principles:
  single_expectation: "Each 'it' block should contain only one expectation"
  descriptive_names: "Use descriptive test names that explain the behavior being tested"
  context_organization: "Use nested contexts to organize related test scenarios"
```

**Key BetterSpecs Rules Summary** (see `.betterspecs.yml` for complete configuration):
- `single_expectation`: One expectation per `it` block for focused, maintainable tests
- `context_organization`: Use nested contexts to organize related test scenarios
- `descriptive_names`: Use descriptive test names that explain the behavior being tested
- `factory_usage`: Use FactoryBot for test data creation
- `shared_examples`: Extract common test patterns into shared examples
- `spec_helpers`: Utilize or create methods in spec_helper for common setup and utilities
- `stubbing_mocking`: Mock/Stub external dependencies and services to isolate tests

```ruby
# Good: Single expectation per test
it 'validates presence of name' do
  lock_code = build(:lock_code, name: nil)
  expect(lock_code).not_to be_valid
end

it 'includes error message for missing name' do
  lock_code = build(:lock_code, name: nil)
  lock_code.valid?
  expect(lock_code.errors[:name]).to include("can't be blank")
end

# Bad: Multiple expectations in one test
it 'validates presence of name' do
  lock_code = build(:lock_code, name: nil)
  expect(lock_code).not_to be_valid
  expect(lock_code.errors[:name]).to include("can't be blank")  # Multiple behaviors
end
```

### Structure and Organization

```ruby
# Good: RSpec structure following BetterSpecs (see .betterspecs.yml for complete patterns)
RSpec.describe LockCode, type: :model do
  describe 'associations' do
    it { should belong_to(:company) }
    it { should have_many(:device_lockcodes).dependent(:destroy) }
    it { should have_many(:devices).through(:device_lockcodes) }
  end

  describe 'validations' do
    it { should validate_presence_of(:name) }
    it { should validate_presence_of(:security_code) }
    it { should validate_length_of(:name).is_at_most(255) }
    
    context 'security code uniqueness' do
      let!(:company) { create(:company) }
      let!(:existing_code) { create(:lock_code, company: company, security_code: '12345') }

      it 'validates uniqueness within company scope' do
        duplicate_code = build(:lock_code, company: company, security_code: '12345')
        expect(duplicate_code).not_to be_valid
      end

      it 'includes error message for duplicate security code' do
        duplicate_code = build(:lock_code, company: company, security_code: '12345')
        duplicate_code.valid?
        expect(duplicate_code.errors[:security_code]).to include('has already been taken')
      end

      it 'allows same security code in different companies' do
        other_company = create(:company)
        code_in_other_company = build(:lock_code, company: other_company, security_code: '12345')
        expect(code_in_other_company).to be_valid
      end
    end
  end

  describe '#expired?' do
    context 'when to_time is present' do
      context 'when to_time is in the past' do
        let(:lock_code) { create(:lock_code, to_time: 1.hour.ago) }

        it 'returns true' do
          expect(lock_code.expired?).to be true
        end
      end

      context 'when to_time is in the future' do
        let(:lock_code) { create(:lock_code, to_time: 1.hour.from_now) }

        it 'returns false' do
          expect(lock_code.expired?).to be false
        end
      end
    end

    context 'when to_time is not present' do
      let(:lock_code) { create(:lock_code, to_time: nil) }

      it 'returns false' do
        expect(lock_code.expired?).to be false
      end
    end
  end

  describe '#activate!' do
    let(:lock_code) { create(:lock_code, status: :inactive) }

    it 'updates status to active' do
      expect { lock_code.activate! }.to change(lock_code, :status).to('active')
    end

    it 'sets activated_at timestamp' do
      expect { lock_code.activate! }.to change(lock_code, :activated_at).from(nil)
    end

    it 'enqueues activation worker' do
      expect(LockCodes::ActivationWorker).to receive(:perform_async).with(lock_code.id)
      lock_code.activate!
    end
  end
end
```

**For complete testing patterns and examples, refer to `.betterspecs.yml`**

### Shared Examples

```ruby
# Good: Shared examples for reusable test patterns (see .betterspecs.yml for complete patterns)
# spec/support/shared_examples/lock_code_examples.rb
RSpec.shared_examples 'a valid lock code' do
  it 'has a present name' do
    expect(lock_code.name).to be_present
  end

  it 'has a present security code' do
    expect(lock_code.security_code).to be_present
  end

  it 'has an associated company' do
    expect(lock_code.company).to be_present
  end

  it 'is persisted' do
    expect(lock_code).to be_persisted
  end
end

# Usage in specs
RSpec.describe LockCodeService do
  describe '#call' do
    let(:params) { { name: 'Test Code', security_code: '12345' } }
    let(:service) { described_class.new(params) }
    let(:lock_code) { service.call }

    context 'with valid parameters' do
      include_examples 'a valid lock code'
    end
  end
end
```

**For complete shared examples patterns, refer to `.betterspecs.yml`**

### Factory Bot Patterns

```ruby
# Good: Factory Bot patterns for test data (see .betterspecs.yml for complete patterns)
# spec/factories/lock_codes.rb
FactoryBot.define do
  factory :lock_code do
    sequence(:name) { |n| "Lock Code #{n}" }
    sequence(:security_code) { |n| "#{1000 + n}" }
    company
    validity_type { LockCode::VALIDITY_TYPE_HASH.key('Never Expires') }
    code_type { LockCode::CODE_TYPE.key('Hub Lock Code') }

    trait :expired do
      to_time { 1.hour.ago }
    end

    trait :with_devices do
      after(:create) do |lock_code|
        create_list(:device_lockcode, 2, lock_code: lock_code)
      end
    end
  end
end
```

**For complete Factory Bot patterns and examples, refer to `.betterspecs.yml`**

### Controller Testing

```ruby
# Good: Controller testing patterns (see .betterspecs.yml for complete patterns)
RSpec.describe LockCodesController, type: :controller do
  let(:company) { create(:company) }
  let(:agent) { create(:agent, company: company) }

  before { sign_in agent }

  describe 'POST #create' do
    context 'with valid parameters' do
      let(:valid_params) do
        {
          lock_code: {
            name: 'Test Lock Code',
            security_code: '12345',
            validity_type: LockCode::VALIDITY_TYPE_HASH.key('Never Expires'),
          },
        }
      end

      it 'creates a new lock code' do
        expect {
          post :create, params: valid_params
        }.to change(LockCode, :count).by(1)
      end

      it 'returns success response' do
        post :create, params: valid_params
        expect(response).to have_http_status(:created)
      end
    end

    context 'with invalid parameters' do
      let(:invalid_params) do
        {
          lock_code: {
            name: '',
            security_code: '',
          },
        }
      end

      it 'does not create a lock code' do
        expect {
          post :create, params: invalid_params
        }.not_to change(LockCode, :count)
      end

      it 'returns error response' do
        post :create, params: invalid_params
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end
  end
end
```

**For complete controller testing patterns and examples, refer to `.betterspecs.yml`**

---

**Note**: This Testing Guidelines section provides key examples and patterns. For the complete set of BetterSpecs rules, patterns, and examples, always refer to `.betterspecs.yml` in the project root.

## Code Documentation Standards

### Ruby Documentation

```ruby
# Good: Comprehensive class documentation
# Service class responsible for managing lock code lifecycle and device synchronization.
# Handles creation, validation, activation, and device distribution of lock codes.
#
# @example Create a new lock code
#   service = LockCodeService.new(name: 'Main Entry', security_code: '12345')
#   lock_code = service.call
#
# @example Activate existing lock code
#   service = LockCodeService.new(lock_code: existing_code)
#   service.activate!
#
class LockCodeService
  # Creates a new lock code and distributes it to associated devices.
  #
  # @param params [Hash] Lock code parameters
  # @option params [String] :name The human-readable name for the lock code
  # @option params [String] :security_code The numeric code for device access
  # @option params [Integer] :validity_type Type of validity (never expires, specific period, etc.)
  #
  # @return [LockCode] The created lock code instance
  # @raise [ValidationError] When required parameters are missing or invalid
  # @raise [ServiceError] When device synchronization fails
  #
  def call(params)
    validate_business_rules(params)
    lock_code = create_lock_code(params)
    sync_with_devices(lock_code) if lock_code.persisted?
    lock_code
  end

  private

  # Validates business-specific rules beyond model validations.
  # Ensures security code uniqueness within property scope and validates device compatibility.
  #
  # @param params [Hash] Parameters to validate
  # @raise [ValidationError] When business rules are violated
  def validate_business_rules(params)
    # Implementation with detailed comments explaining business logic
  end
end
```

### JavaScript Documentation

```javascript
/**
 * Manages lock code operations including creation, activation, and device synchronization.
 * Provides real-time updates and handles user interactions for lock code management.
 * 
 * @class LockCodeManager
 * @example
 * const manager = new LockCodeManager('#lock-codes-container');
 * manager.initialize();
 */
class LockCodeManager {
  /**
   * @param {string} containerId - The CSS selector for the container element
   * @param {Object} options - Configuration options
   * @param {boolean} options.autoRefresh - Whether to automatically refresh data
   * @param {number} options.refreshInterval - Refresh interval in milliseconds
   */
  constructor(containerId, options = {}) {
    this.container = $(containerId);
    this.options = {
      autoRefresh: true,
      refreshInterval: 30000,
      ...options,
    };
  }

  /**
   * Creates a new lock code with validation and device synchronization.
   * 
   * @param {Object} lockCodeData - The lock code data
   * @param {string} lockCodeData.name - Human-readable name
   * @param {string} lockCodeData.securityCode - Numeric access code
   * @param {number} lockCodeData.validityType - Type of validity period
   * @returns {Promise<Object>} Promise resolving to creation result
   * @throws {ValidationError} When input data is invalid
   * 
   * @example
   * try {
   *   const result = await manager.createLockCode({
   *     name: 'Front Door',
   *     securityCode: '12345',
   *     validityType: 1
   *   });
   *   console.log('Lock code created:', result.data);
   * } catch (error) {
   *   console.error('Creation failed:', error.message);
   * }
   */
  async createLockCode(lockCodeData) {
    this.validateInput(lockCodeData);
    
    try {
      const response = await ApiClient.post('/api/lock_codes', lockCodeData);
      
      if (response.success) {
        this.handleSuccessfulCreation(response.data);
        return response;
      } else {
        throw new Error(response.error.message);
      }
    } catch (error) {
      this.handleCreationError(error);
      throw error;
    }
  }
}
```

### API Documentation

```ruby
# Good: API endpoint documentation
class Api::LockCodesController < ApiController
  # Creates a new lock code for the authenticated company
  #
  # @api {post} /api/lock_codes Create Lock Code
  # @apiName CreateLockCode
  # @apiGroup LockCodes
  # @apiVersion 1.0.0
  #
  # @apiParam {String} name Lock code name (required, max 255 characters)
  # @apiParam {String} security_code Numeric code (required, 4-8 digits)
  # @apiParam {Number} validity_type Validity type (1=Never Expires, 2=Specific Period)
  # @apiParam {DateTime} [from_time] Start time for specific period validity
  # @apiParam {DateTime} [to_time] End time for specific period validity
  # @apiParam {Number[]} [device_ids] Array of device IDs to associate
  #
  # @apiSuccess {Boolean} success Operation success status
  # @apiSuccess {Object} data Lock code data
  # @apiSuccess {Number} data.id Lock code ID
  # @apiSuccess {String} data.name Lock code name
  # @apiSuccess {String} data.status Current status
  #
  # @apiError {Boolean} success=false Operation failed
  # @apiError {String} message Error description
  # @apiError {Object} errors Detailed validation errors
  #
  # @apiExample {json} Request Example:
  #   {
  #     "name": "Front Door Access",
  #     "security_code": "12345",
  #     "validity_type": 1,
  #     "device_ids": [1, 2, 3]
  #   }
  #
  # @apiExample {json} Success Response:
  #   {
  #     "success": true,
  #     "data": {
  #       "id": 123,
  #       "name": "Front Door Access",
  #       "security_code": "12345",
  #       "status": "active"
  #     }
  #   }
  def create
    # Implementation
  end
end
```

## Performance Guidelines

### Database Performance

```ruby
# Good: Efficient queries with proper joins and includes
def dashboard_data
  {
    active_codes: current_company.lock_codes
                    .includes(:devices, :device_lockcodes)
                    .where(status: :active)
                    .order(:name),
    device_stats: current_company.devices
                    .joins(:device_lockcodes)
                    .group('devices.device_type')
                    .count,
  }
end

# Good: Use database aggregations instead of Ruby calculations
def lock_code_statistics
  LockCode.where(company: current_company)
          .group(:status)
          .group_by_month(:created_at, last: 12)
          .count
end

# Good: Pagination for large datasets
def index
  @lock_codes = current_company.lock_codes
                  .includes(:devices)
                  .page(params[:page])
                  .per(25)
end
```

### Check Values Before Modification

**Always check current database values before modifying them to avoid unnecessary updates and improve performance:**

```ruby
# Good: Check before update to avoid unnecessary database writes
def update_lock_code_status(lock_code_id, new_status)
  lock_code = LockCode.find(lock_code_id)
  
  # Only update if the status is actually different
  if lock_code.status != new_status
    lock_code.update(status: new_status)
    notify_devices_of_status_change(lock_code)
  end
end

# Good: Use conditional updates in migrations
class UpdateExistingRecords < ActiveRecord::Migration[7.0]
  def change
    # Check current values before updating
    execute <<-SQL
      UPDATE lock_codes 
      SET status = 'active' 
      WHERE status IS NULL OR status = ''
    SQL
  end
end

# Good: Bulk update with conditions
def bulk_activate_lock_codes(lock_code_ids)
  # Only update records that need activation
  LockCode.where(id: lock_code_ids)
          .where.not(status: 'active')  # Check current status
          .update_all(status: 'active', activated_at: Time.current)
end

# Good: Use Rails' touch method wisely
def mark_as_accessed(resource)
  # Only update updated_at if it hasn't been updated recently
  if resource.updated_at < 1.hour.ago
    resource.touch
  end
end

# Good: Conditional attribute assignment
class LockCode < ApplicationRecord
  def update_security_code(new_code)
    return if security_code == new_code  # No change needed
    
    # Validate the new code format
    return unless valid_security_code?(new_code)
    
    update!(security_code: new_code)
    sync_with_devices
  end
  
  private
  
  def valid_security_code?(code)
    code.present? && code.match?(/\A\d{4,8}\z/)
  end
end

# Good: Database-level conditional updates
def update_device_status(device_id, new_status)
  # Use database constraints to prevent unnecessary updates
  Device.where(id: device_id)
        .where.not(status: new_status)  # Only update if different
        .update_all(status: new_status, updated_at: Time.current)
end
```

#### Batching for Large Datasets

**For large databases (>1000 records), use batching to prevent memory issues:**

```ruby
# find_in_batches: Process records in chunks
def bulk_update_lock_codes(company_id, new_status)
  LockCode.where(company_id: company_id)
          .find_in_batches(batch_size: 1000) do |batch|
    batch.each { |lock_code| update_lock_code(lock_code, new_status) }
  end
end

# in_batches: Memory-efficient queries
def generate_report(company_id)
  LockCode.where(company_id: company_id)
          .in_batches(of: 500) do |batch|
    process_batch_for_report(batch)
  end
end

# find_each: Individual record processing with auto-batching
def sync_all_devices
  Device.find_each(batch_size: 200) do |device|
    sync_device_status(device)
  end
end
```

### Caching Strategy

```ruby
# Good: Fragment caching for expensive operations
class Company < ApplicationRecord
  def device_summary
    Rails.cache.fetch("company_#{id}_device_summary", expires_in: 5.minutes) do
      calculate_device_summary
    end
  end

  private

  def calculate_device_summary
    # Expensive calculation
  end
end

# Good: Low-level caching for API responses
def lock_codes_json
  cache_key = "company_#{current_company.id}_lock_codes_#{lock_codes_cache_key}"
  
  Rails.cache.fetch(cache_key, expires_in: 2.minutes) do
    current_company.lock_codes.active.to_json(include: :devices)
  end
end
```

### Background Jobs

```ruby
# Good: Async processing for heavy operations
class LockCodes::SyncDevicesWorker
  include Sidekiq::Worker
  
  sidekiq_options queue: :critical, retry: 3

  # Synchronizes lock code with all associated devices
  #
  # @param lock_code_id [Integer] ID of the lock code to sync
  # @param force_update [Boolean] Whether to force update even if already synced
  def perform(lock_code_id, force_update = false)
    lock_code = LockCode.find(lock_code_id)
    
    lock_code.devices.find_each do |device|
      next if !force_update && device_already_synced?(device, lock_code)
      
      sync_lock_code_to_device(device, lock_code)
    end
  rescue ActiveRecord::RecordNotFound => e
    Rails.logger.error "Lock code not found: #{e.message}"
  end

  private

  def sync_lock_code_to_device(device, lock_code)
    # Implementation with proper error handling
  end
end
```

## Security Guidelines

### Input Validation and Sanitization

```ruby
# Good: Strong parameters and validation
def lock_code_params
  params.require(:lock_code)
        .permit(:name, :security_code, :validity_type, :from_time, :to_time, device_ids: [])
        .tap do |permitted|
          # Additional sanitization
          permitted[:name] = ActionController::Base.helpers.sanitize(permitted[:name])
          permitted[:security_code] = permitted[:security_code].to_s.gsub(/\D/, '') # Only digits
        end
end

# Good: SQL injection prevention
def search_lock_codes(query)
  current_company.lock_codes
                 .where('name ILIKE ?', "%#{sanitize_sql_like(query)}%")
                 .limit(50)
end
```

### Authentication and Authorization

```ruby
# Good: Proper authorization checks
class LockCodesController < ApplicationController
  before_action :authenticate_agent!
  before_action :authorize_lock_code_access!, only: [:show, :edit, :update, :destroy]

  private

  def authorize_lock_code_access!
    @lock_code = current_company.lock_codes.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    redirect_to lock_codes_path, alert: 'Lock code not found or access denied'
  end
end

# Good: Policy-based authorization
class LockCodePolicy < ApplicationPolicy
  def create?
    user.agent? && user.company == record.company
  end

  def update?
    user.agent? && user.company == record.company && !record.expired?
  end

  def destroy?
    user.admin? || (user.manager? && user.company == record.company)
  end
end
```

## Code Review Guidelines

### Copilot's Review Principles

**As an AI code reviewer, Copilot must:**

#### Core Review Principles:
- **Self-Validation**: Always validate generated code against this document's standards
- **Security First**: Prioritize security in all generated code and identify potential vulnerabilities
- **Performance Awareness**: Consider performance implications and optimization opportunities
- **Standards Compliance**: Ensure adherence to RuboCop, Pronto, ESLint, and BetterSpecs configurations
- **Continuous Improvement**: Learn from each generation to improve future code quality

### Pre-Generation Quality Assurance

**Before finalizing generated code, Copilot must verify:**

```ruby
# ✅ Code follows established patterns from this document
# ✅ Generated code passes RuboCop and Pronto validation (.rubocop.yml)
# ✅ Security best practices are implemented
# ✅ Performance guidelines are followed
# ✅ Appropriate error handling and logging included
# ✅ Database queries are optimized (includes, batching, etc.)
# ✅ Tests can be easily written for the generated code
# ✅ Documentation standards are followed
```

### Code Quality Validation Checklist

**Copilot must validate all generated code against these standards:**

#### Architecture Validation
- [ ] **SOLID Principles**: Code follows single responsibility, open/closed, Liskov substitution, interface segregation, and dependency inversion
- [ ] **MVC Separation**: Controllers handle HTTP only, models contain business logic, services orchestrate complex operations
- [ ] **DRY Principle**: No code duplication through proper abstractions
- [ ] **Appropriate Abstractions**: Services, concerns, modules, and helpers used where beneficial

#### Code Quality Validation
- [ ] **Readability**: Self-documenting code with clear, descriptive variable and method names
- [ ] **Complexity**: Methods under 10 lines, classes under 300 lines
- [ ] **Error Handling**: Proper exception handling and comprehensive logging
- [ ] **Resource Management**: Database connections, file handles properly managed

### Code Removal Validation
- [ ] **Check References**: Scan the workspace to confirm that the removed symbol (function, class, constant, or variable) is not referenced anywhere else in the project, including tests, configuration files, or imports.
- [ ] **Suggest Safe Removal**: If no active references exist, suggest removing the full definition and any related documentation, helper references, or exports.

#### Security Validation
- [ ] **Input Validation**: All user inputs validated and sanitized
- [ ] **SQL Injection Prevention**: Parameterized queries used exclusively
- [ ] **Authentication/Authorization**: Proper access controls and authorization checks
- [ ] **Data Protection**: Sensitive data never logged or exposed inappropriately

#### Database & Performance Validation
- [ ] **Query Optimization**: Includes/joins used to prevent N+1 queries
- [ ] **Indexing Strategy**: Appropriate indexes created for new queries
- [ ] **Migration Safety**: Safe, tested, and rollback-capable migrations
- [ ] **Memory Management**: Batching used for large datasets

#### Testing Validation
- [ ] **Test Coverage**: Critical paths and edge cases are testable
- [ ] **BetterSpecs Compliance**: All BetterSpecs guidelines from `.betterspecs.yml` followed
- [ ] **Edge Cases**: Error conditions and boundary cases handled appropriately
- [ ] **Factory Usage**: FactoryBot patterns used for consistent test data

#### Documentation Validation
- [ ] **Code Comments**: Complex business logic and non-obvious decisions documented
- [ ] **API Documentation**: Public methods documented with proper YARD/JSdoc comments
- [ ] **Inline Documentation**: Examples and parameter descriptions included

### Copilot's Self-Review Process

#### 1. Automated Validation Steps
**Copilot must perform these automated checks:**

- [ ] **Syntax Validation**: Ensure generated code has no syntax errors
- [ ] **RuboCop/Pronto Compliance**: Verify code passes `.rubocop.yml` and Pronto rules
- [ ] **ESLint Compliance**: Check JavaScript code against `.eslintrc.js`
- [ ] **Security Scan**: Identify potential security vulnerabilities
- [ ] **Performance Analysis**: Check for performance anti-patterns

#### 2. Pattern Recognition and Correction
**Copilot must identify and correct:**

- [ ] **Anti-patterns**: Recognize common bad patterns and replace with good ones
- [ ] **Code Smells**: Identify maintainability issues and refactor
- [ ] **Security Issues**: Detect and fix potential vulnerabilities
- [ ] **Performance Issues**: Optimize database queries and algorithms

#### 3. Improvement Suggestions
**When reviewing generated code, Copilot should:**

```markdown
# Self-improvement format:
🔍 **Analysis**: What pattern/issue was identified
✅ **Improvement**: How the code was enhanced
💡 **Rationale**: Why this improvement matters
📋 **Standard**: Which guideline from this document was applied
```

### Common Patterns to Avoid and Follow

#### Ruby/Rails Specific Patterns
```ruby
# ❌ Bad: Law of Demeter violation
user.company.lock_codes.first.device.name

# ✅ Good: Delegate through service
LockCodeService.new(user.company).get_lock_codes

# ❌ Bad: Business logic in controller
def create
  if params[:lock_code][:security_code].length < 4
    # validation logic here
  end
end

# ✅ Good: Validation in model/service
def create
  @lock_code = LockCodeService.new(lock_code_params).call
end
```

#### Database Query Patterns
```ruby
# ❌ Bad: N+1 query
companies.each do |company|
  puts company.lock_codes.count  # N queries
end

# ✅ Good: Single optimized query
companies.joins(:lock_codes)
         .group('companies.id')
         .count

# ❌ Bad: Missing transaction safety
def transfer_lock_code
  lock_code.update!(company_id: new_company_id)
  audit_log.create!(action: 'transferred')  # Could fail
end

# ✅ Good: Transaction wrapper for data integrity
def transfer_lock_code
  LockCode.transaction do
    lock_code.update!(company_id: new_company_id)
    audit_log.create!(action: 'transferred')
  end
end
```

#### Security Pattern Corrections
```ruby
# ❌ Bad: SQL injection vulnerability
LockCode.where("name LIKE '%#{params[:query]}%'")

# ✅ Good: Parameterized query for security
LockCode.where("name LIKE ?", "%#{sanitize_sql_like(params[:query])}%")

# ❌ Bad: Mass assignment vulnerability
user.update(params[:user])  # Updates all attributes

# ✅ Good: Strong parameters for data protection
user.update(user_params)

def user_params
  params.require(:user).permit(:name, :email)
end
```

### Validation Tools and Commands

**Copilot should use these tools to validate generated code:**

#### Ruby/Rails Validation:
```bash
# Check RuboCop compliance
rubocop app/models/lock_code.rb

# Run Rails best practices
rails_best_practices

# Security vulnerability scan
brakeman

# Comprehensive code analysis (aggregates multiple tools)
pronto run

# Container and dependency vulnerability scan
trivy fs --scanners vuln,secret,misconfig .

# Test coverage analysis
simplecov
```

#### JavaScript Validation:
```bash
# ESLint compliance check
eslint app/javascript/lock_codes.js

# Security scan for JavaScript
npm audit
```

#### Database Validation:
```bash
# Migration safety check
rails db:migrate:redo

# Query performance analysis
rails db:explain SELECT * FROM lock_codes WHERE company_id = 1
```

### Continuous Learning and Improvement

**Copilot's self-improvement guidelines:**

#### Pattern Recognition Learning:
- [ ] **Identify Patterns**: Recognize when similar code patterns are used
- [ ] **Standardize Solutions**: Apply consistent solutions to similar problems
- [ ] **Update Knowledge Base**: Learn from corrections and apply to future generations

#### Quality Metrics Tracking:
- [ ] **Validation Success Rate**: Track how often generated code passes validation
- [ ] **Common Issues**: Identify frequently corrected patterns
- [ ] **Improvement Areas**: Focus on weak areas for enhancement

#### Reference Standards:
- [ ] **Document Compliance**: Always reference this document's guidelines
- [ ] **Configuration Files**: Follow `.rubocop.yml`, `.prontorc` (if configured), `.eslintrc.js`, `.betterspecs.yml`
- [ ] **Project Patterns**: Maintain consistency with existing codebase patterns

### Copilot's Code Generation Workflow

**Standard workflow for high-quality code generation:**

1. **Requirements Analysis**: Understand the task and required functionality
2. **Pattern Matching**: Identify similar patterns from this document and codebase
3. **Code Generation**: Generate initial code following established patterns
4. **Self-Validation**: Run automated checks and manual review
5. **Pattern Correction**: Apply anti-pattern fixes and improvements
6. **Security Review**: Validate security implementations
7. **Performance Optimization**: Apply performance best practices
8. **Documentation**: Ensure proper code documentation
9. **Final Validation**: Confirm all standards are met
```

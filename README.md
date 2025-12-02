# Reseg

A Ruby gem to parse and format REservation SEGments into organized trips.

Reseg takes raw reservation data containing flights, trains, and hotel bookings, groups them into trips based on a traveler's home base city, and outputs human-readable itineraries.

### Format Specifications

| Field | Format | Example |
|-------|--------|---------|
| IATA Code | 3-letter code | `SVQ`, `BCN`, `MAD` |
| Date | ISO 8601 extended | `2025-01-05` |
| Time | 24-hour format | `20:40`, `09:30` |

## How Trip Building Works

1. **Parsing**: The input is scanned line by line, extracting reservation blocks and segment data
2. **Segment Creation**: Each segment line is parsed into typed segment objects (Flight, Train, Hotel)
3. **Sorting**: All segments are sorted chronologically by start time
4. **Trip Assembly**:
   - A trip begins when a flight/train departs from the base city
   - A trip ends when a flight/train arrives at the base city
   - Connecting flights within 24 hours are grouped together
5. **Hotel Insertion**: Hotel segments are matched to trips based on location and dates, then inserted after the corresponding arrival segment

## Architecture

```
ResegFormatter
├── Core/
│   ├── Segment (base class)
│   ├── FlightSegment
│   ├── TrainSegment
│   ├── HotelSegment
│   ├── Reservation
│   └── Trip
├── Parsing/
│   ├── Scanner (tokenizes input)
│   ├── Statement (token wrapper)
│   └── SegmentParser (parses segment lines)
├── ReservationBuilder (groups segments into reservations)
├── TripBuilder (groups segments into trips)
└── Context (holds base city and time zone)
```

## Usage

### Basic Usage

```ruby
require 'reseg'

input = <<~INPUT
  RESERVATION
  SEGMENT: Flight SVQ 2025-01-05 20:40 -> BCN 22:10
  SEGMENT: Flight BCN 2025-01-10 10:30 -> SVQ 11:50

  RESERVATION
  SEGMENT: Hotel BCN 2025-01-05 -> 2025-01-10
INPUT

# Format as a human-readable string
output = Reseg.format(input, based_city: "SVQ")
puts output

# Output:
# TRIP TO BCN
# Flight from SVQ to BCN at 2025-01-05 20:40 to 22:10
# Hotel at BCN on 2025-01-05 to 2025-01-10
# Flight from BCN to SVQ at 2025-01-10 10:30 to 11:50
```

### Programmatic Access

For more control, use the `parse` method to get structured trip objects:

```ruby
result = Reseg.parse(input, based_city: "SVQ")

if result.success?
  result.trips.each do |trip|
    puts "Trip to #{trip.destination_iata}"
    puts "Duration: #{trip.duration} seconds"

    trip.segments.each do |segment|
      case segment.type
      when :flight
        puts "  Flight: #{segment.origin_iata} -> #{segment.destination_iata}"
      when :train
        puts "  Train: #{segment.origin_iata} -> #{segment.destination_iata}"
      when :hotel
        puts "  Hotel at #{segment.location_iata}"
      end
    end
  end
else
  puts "Errors: #{result.errors.join(', ')}"
end
```

### Time Zone Configuration

By default, the time zone is inferred from the base city's IATA code. You can override this:

```ruby
Reseg.format(input, based_city: "SVQ", time_zone: "Europe/Madrid")
```

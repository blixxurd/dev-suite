We want a small service that keeps a local record of recent earthquakes and answers questions about them over HTTP.

1. The data comes from the USGS past-day feed, https://earthquake.usgs.gov/earthquakes/feed/v1.0/summary/all_day.geojson. We trigger a refresh ourselves. Refreshing twice must not create duplicates, and an event USGS has revised should show its latest values.
2. List earthquakes, newest first, optionally filtered by minimum magnitude and by a time range.
3. Summarize a time range: how many, the largest, and a count per whole-number magnitude band.
4. The API answers from the local record, so it keeps working when USGS is unreachable.

Not wanted: a user interface, accounts.

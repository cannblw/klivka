export function localDateFor(date, timeZone) {
  if (!timeZone) {
    const year = date.getFullYear()
    const month = String(date.getMonth() + 1).padStart(2, "0")
    const day = String(date.getDate()).padStart(2, "0")

    return `${year}-${month}-${day}`
  }

  const parts = new Intl.DateTimeFormat("en", {
    timeZone,
    year: "numeric",
    month: "2-digit",
    day: "2-digit"
  }).formatToParts(date)
  const values = Object.fromEntries(parts.map((part) => [ part.type, part.value ]))

  return `${values.year}-${values.month}-${values.day}`
}

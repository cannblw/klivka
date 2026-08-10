export function browserTimeZone() {
  try {
    return Intl.DateTimeFormat().resolvedOptions().timeZone || null
  } catch (error) {
    console.error("Could not detect the browser time zone", error)
    return null
  }
}

import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [ "month", "day", "year", "age", "basis" ]
  static values = { today: String, anchorYear: Number }

  connect() {
    this.source = this.basisTarget.value || (this.yearTarget.value === "" ? "age" : "year")
    this.synchronize()
  }

  yearChanged() {
    this.source = "year"
    this.basisTarget.value = this.yearTarget.value === "" ? "" : this.source
    this.synchronize()
  }

  ageChanged() {
    this.source = "age"
    this.basisTarget.value = this.ageTarget.value === "" ? "" : this.source
    this.synchronize()
  }

  dateChanged() {
    this.synchronize()
  }

  synchronize() {
    if (this.source === "year") {
      const age = this.calculatedAge
      this.ageTarget.value = age === null ? "" : age
    } else {
      const year = this.calculatedYear
      this.yearTarget.value = year === null ? "" : year
    }
  }

  get calculatedYear() {
    if (this.ageTarget.value === "") return null

    const age = Number(this.ageTarget.value)
    const month = Number(this.monthTarget.value)
    const day = Number(this.dayTarget.value)
    const [ todayYear, todayMonth, todayDay ] = this.todayValue.split("-").map(Number)

    if (!Number.isInteger(age) || age < 0 || !this.validMonthAndDay(month, day)) return null

    const observedDay = Math.min(day, this.daysInMonth(todayYear, month))
    const birthdayIsAhead = month > todayMonth || (month === todayMonth && observedDay > todayDay)
    const year = todayYear - age - (birthdayIsAhead ? 1 : 0)
    return year > 0 ? year : null
  }

  get calculatedAge() {
    if (this.yearTarget.value === "") return null

    const year = Number(this.yearTarget.value)
    const month = Number(this.monthTarget.value)
    const day = Number(this.dayTarget.value)
    const [ todayYear, todayMonth, todayDay ] = this.todayValue.split("-").map(Number)

    if (!Number.isInteger(year) || year < 1 || year > todayYear ||
        !this.validMonthAndDay(month, day) || day > this.daysInMonth(year, month)) return null

    const observedDay = Math.min(day, this.daysInMonth(todayYear, month))
    const birthdayIsAhead = month > todayMonth || (month === todayMonth && observedDay > todayDay)
    const age = todayYear - year - (birthdayIsAhead ? 1 : 0)
    return age >= 0 ? age : null
  }

  validMonthAndDay(month, day) {
    return Number.isInteger(month) && month >= 1 && month <= 12 &&
      Number.isInteger(day) && day >= 1 && day <= this.daysInMonth(this.anchorYearValue, month)
  }

  daysInMonth(year, month) {
    return new Date(Date.UTC(year, month, 0)).getUTCDate()
  }
}

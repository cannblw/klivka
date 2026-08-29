import PersistentSortableController from "lib/persistent_sortable_controller"

export default class extends PersistentSortableController {
  get orderParameter() {
    return "contact_method_ids"
  }

  itemId(item) {
    return item.dataset.contactMethodId
  }

  get saveErrorMessage() {
    return "Could not save the contact method order"
  }
}

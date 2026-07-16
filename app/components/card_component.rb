class CardComponent < ViewComponent::Base
  erb_template <<~ERB
    <div class="mx-auto mt-8 w-full max-w-sm rounded-xl border border-gray-200 bg-white p-6 shadow-sm">
      <%= content %>
    </div>
  ERB

  def call
    content
  end
end

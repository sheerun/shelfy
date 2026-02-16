class BooksController < ApplicationController
  def index
    execute(Library::ListBooks, page: params[:page], per_page: params[:per_page])
  end

  def show
    execute(Library::GetBook, id: params[:id])
  end

  def create
    execute(Library::RegisterBook, book_params)
  end

  def update
    execute(Library::UpdateBook, book_params.merge(id: params[:id]))
  end

  def destroy
    execute(Library::DeregisterBook, id: params[:id])
  end

  private

  def book_params
    params.expect(book: [:serial_number, :title, :author])
  end
end

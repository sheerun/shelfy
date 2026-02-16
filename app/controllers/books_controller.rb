class BooksController < ApplicationController
  def index
    execute(Library::ListBooks, page: params[:page], per_page: params[:per_page], status: params[:status])
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

  def borrow
    execute(Library::BorrowBook, book_id: params[:id], reader_id: params[:reader_id])
  end

  def return
    execute(Library::ReturnBook, book_id: params[:id])
  end

  private

  def book_params
    params.expect(book: [:serial_number, :title, :author])
  end
end

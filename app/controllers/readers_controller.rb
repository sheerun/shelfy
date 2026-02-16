class ReadersController < ApplicationController
  def index
    execute(Library::ListReaders, page: params[:page], per_page: params[:per_page])
  end

  def show
    execute(Library::GetReader, id: params[:id])
  end

  def create
    execute(Library::RegisterReader, reader_params)
  end

  def update
    execute(Library::UpdateReader, reader_params.merge(id: params[:id]))
  end

  def destroy
    execute(Library::DeregisterReader, id: params[:id])
  end

  private

  def reader_params
    params.expect(reader: [:serial_number, :email, :full_name])
  end
end

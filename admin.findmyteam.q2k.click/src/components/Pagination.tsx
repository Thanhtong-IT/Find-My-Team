interface PaginationProps {
  page: number;
  totalPages: number;
  totalElements: number;
  itemLabel: string;
  onPage: (page: number) => void;
}

export function Pagination({ page, totalPages, totalElements, itemLabel, onPage }: PaginationProps) {
  return (
    <div className="pagination">
      <span className="pagination-info">
        {totalElements} {itemLabel}
      </span>
      <div className="pagination-controls">
        <button
          className="pagination-btn"
          disabled={page <= 0}
          onClick={() => onPage(page - 1)}
        >
          ← Trước
        </button>
        <span className="pagination-page">
          {page + 1} / {Math.max(totalPages, 1)}
        </span>
        <button
          className="pagination-btn"
          disabled={page + 1 >= totalPages}
          onClick={() => onPage(page + 1)}
        >
          Sau →
        </button>
      </div>
    </div>
  );
}

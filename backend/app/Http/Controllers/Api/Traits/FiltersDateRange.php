<?php

namespace App\Http\Controllers\Api\Traits;

use Illuminate\Http\Request;

/**
 * Reusable date range and search filtering for query builders.
 */
trait FiltersDateRange
{
    /**
     * Apply start_date and end_date filters to a query.
     *
     * @param  \Illuminate\Database\Eloquent\Builder|\Illuminate\Database\Query\Builder  $query
     */
    protected function applyDateFilter($query, Request $request, string $dateColumn = 'date')
    {
        if ($request->filled('start_date')) {
            $query->whereDate($dateColumn, '>=', $request->string('start_date'));
        }
        if ($request->filled('end_date')) {
            $query->whereDate($dateColumn, '<=', $request->string('end_date'));
        }

        return $query;
    }

    /**
     * Apply a single date filter (exact match).
     *
     * @param  \Illuminate\Database\Eloquent\Builder|\Illuminate\Database\Query\Builder  $query
     */
    protected function applySingleDateFilter($query, Request $request, string $dateColumn = 'date', string $paramName = 'date')
    {
        if ($request->filled($paramName)) {
            $query->whereDate($dateColumn, $request->input($paramName));
        }

        return $query;
    }
}

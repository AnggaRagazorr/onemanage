<!DOCTYPE html>
<html>

<head>
    <title>Laporan Patroli</title>
    <style>
        body {
            font-family: sans-serif;
            font-size: 10pt;
        }

        table {
            width: 100%;
            border-collapse: collapse;
            margin-top: 20px;
        }

        th,
        td {
            border: 1px solid #333;
            padding: 6px;
            text-align: left;
        }

        th {
            background-color: #f2f2f2;
        }

        .header {
            text-align: center;
            margin-bottom: 20px;
        }

        .meta {
            margin-bottom: 10px;
        }
    </style>
</head>

<body>
    <div class="header">
        <h2>Laporan Patroli Security</h2>
        <p>Generated: {{ now()->format('d M Y H:i') }}</p>
    </div>

    @if(isset($start_date) && isset($end_date))
        <div class="meta">
            <strong>Periode:</strong> {{ $start_date }} s/d {{ $end_date }}
        </div>
    @endif

    <table>
        <thead>
            <tr>
                <th>No</th>
                <th>Waktu</th>
                <th>Security</th>
                <th>Area</th>
                <th>Barcode</th>
                <th>Kondisi</th>
                <th>Foto</th>
            </tr>
        </thead>
        <tbody>
            @foreach($data as $index => $item)
                <tr>
                    <td>{{ $index + 1 }}</td>
                    <td>{{ $item->captured_at->format('d/m/Y H:i') }}</td>
                    <td>{{ $item->user->name ?? '-' }}</td>
                    <td>{{ $item->area }}</td>
                    <td>{{ $item->barcode }}</td>
                    <td>{{ $item->condition ?? '-' }}</td>
                    <td>{{ count($item->photos ?? []) }} foto</td>
                </tr>
            @endforeach
        </tbody>
    </table>
</body>

</html>
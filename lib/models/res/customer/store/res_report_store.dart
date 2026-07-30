
class RevenueReportResponse {
  final bool ok;
  final String range; // "day" | "week" | "month" | "year"
  final RevenueSummary summary;
  final List<RevenueChartItem> chart;

  RevenueReportResponse({
    required this.ok,
    required this.range,
    required this.summary,
    required this.chart,
  });

  factory RevenueReportResponse.fromJson(Map<String, dynamic> json) {
    return RevenueReportResponse(
      ok: json['ok'] ?? false,
      range: json['range'] ?? 'day',
      summary: RevenueSummary.fromJson(json['summary'] ?? {}),
      chart: (json['chart'] as List<dynamic>? ?? [])
          .map((e) => RevenueChartItem.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'ok': ok,
      'range': range,
      'summary': summary.toJson(),
      'chart': chart.map((e) => e.toJson()).toList(),
    };
  }
}

/// ใช้แสดงการ์ดสรุปด้านบน: "รายได้รวม" + "จำนวนออเดอร์"
class RevenueSummary {
  final num totalRevenue;
  final int orderCount;

  RevenueSummary({
    required this.totalRevenue,
    required this.orderCount,
  });

  factory RevenueSummary.fromJson(Map<String, dynamic> json) {
    return RevenueSummary(
      totalRevenue: json['total_revenue'] ?? 0,
      orderCount: json['order_count'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'total_revenue': totalRevenue,
      'order_count': orderCount,
    };
  }
}

class RevenueChartItem {
  final String label;
  final num revenue;
  final int orderCount;

  RevenueChartItem({
    required this.label,
    required this.revenue,
    required this.orderCount,
  });

  factory RevenueChartItem.fromJson(Map<String, dynamic> json) {
    return RevenueChartItem(
      label: json['label'] ?? '',
      revenue: json['revenue'] ?? 0,
      orderCount: json['order_count'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'label': label,
      'revenue': revenue,
      'order_count': orderCount,
    };
  }
}
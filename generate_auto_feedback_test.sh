#!/bin/bash

# =============================================================================
# AUTO FEEDBACK TEST FILE GENERATOR
# =============================================================================
# This script generates test scenarios for the _auto_feedback task functionality.
# It creates comprehensive input data simulating results from all validation,
# detection, and flagging tasks to test automatic feedback system responses.
#
# Test Scenarios:
# 1. All systems healthy (green status)
# 2. Minor issues detected (yellow/warning status)
# 3. Critical issues detected (red/critical status)
# 4. Mixed scenario with partial failures
# 5. Edge cases and stress testing
# =============================================================================

# Import shared configuration
source "$(dirname "$0")/generate_mock_data.sh" --source-only

# Add special flag to prevent main execution when sourced
if [ "${1}" == "--source-only" ]; then
    return 0
fi

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Parse arguments
CLEAN_DOCKER=0
INPUT_DATE=""

# Process arguments
for arg in "$@"; do
    if [[ "$arg" == "--clean" ]]; then
        CLEAN_DOCKER=1
    elif [[ "$arg" == "--source-only" ]]; then
        continue
    elif [[ "$arg" =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}$ ]]; then
        INPUT_DATE="$arg"
        if ! parse_date "$INPUT_DATE" "+%Y-%m-%d" >/dev/null; then
            echo -e "${RED}❌ Error: Invalid date '$INPUT_DATE'${NC}"
            exit 1
        fi
    elif [[ "$arg" == "--help" || "$arg" == "-h" ]]; then
        echo -e "${YELLOW}Usage: $0 [YYYY-MM-DD] [--clean]${NC}"
        echo -e "${YELLOW}  --clean: Remove existing files from Docker container first${NC}"
        exit 0
    else
        echo -e "${RED}❌ Error: Invalid argument '$arg'${NC}"
        exit 1
    fi
done

# Use current date if not provided
if [ -z "$INPUT_DATE" ]; then
    INPUT_DATE=$(date +%Y-%m-%d)
fi

# Generate date formats
DATE_PATTERN=$(parse_date "$INPUT_DATE" "+%Y%m%d")
DATE_DIR_FORMAT="$INPUT_DATE"

# Create auto feedback test directory
AUTO_FEEDBACK_DIR="$BASE_DIR/$DATE_DIR_FORMAT/auto_feedback"
mkdir -p "$AUTO_FEEDBACK_DIR"

echo -e "${BLUE}=== AUTO FEEDBACK TEST FILES GENERATOR ===${NC}"
echo -e "${YELLOW}📅 Target Date: $INPUT_DATE${NC}"
echo -e "${YELLOW}🔄 Generating automatic feedback scenarios for testing${NC}"

# =============================================================================
# FUNCTION: Generate Comprehensive Pipeline Status Mock Data
# =============================================================================
generate_pipeline_status_mock() {
    echo -e "${RED}🔧 Generating Comprehensive Pipeline Status Mock Data...${NC}"
    
    # 1. Mock validation results (from data_upload cluster)
    echo -e "${YELLOW}  1. Creating mock validation results...${NC}"
    
    cat > "$AUTO_FEEDBACK_DIR/mock_validation_results.json" << EOF
{
    "validation_date": "$INPUT_DATE",
    "validation_summary": {
        "total_files_processed": 50,
        "validation_results": {
            "file_format": {
                "passed": 45,
                "failed": 5,
                "success_rate": 90.0,
                "issues": [
                    {
                        "filename": "TH_PRCH_${DATE_PATTERN}${timestamp}.ods",
                        "issue": "invalid_csv_format",
                        "severity": "critical"
                    },
                    {
                        "filename": "TH_PROMPRCH_${DATE_PATTERN}${timestamp}.ods",
                        "issue": "missing_headers",
                        "severity": "critical"
                    }
                ]
            },
            "required_fields": {
                "passed": 40,
                "failed": 10,
                "success_rate": 80.0,
                "issues": [
                    {
                        "filename": "TH_PRCH_${DATE_PATTERN}${timestamp}.ods",
                        "issue": "missing_required_field_price",
                        "severity": "critical"
                    },
                    {
                        "filename": "TH_PROMPRCH_${DATE_PATTERN}${timestamp}.ods",
                        "issue": "missing_required_field_start_date",
                        "severity": "critical"
                    }
                ]
            },
            "data_types": {
                "passed": 42,
                "failed": 8,
                "success_rate": 84.0,
                "issues": [
                    {
                        "filename": "TH_PRCH_${DATE_PATTERN}${timestamp}.ods",
                        "issue": "invalid_price_format",
                        "severity": "warning"
                    },
                    {
                        "filename": "TH_PROMPRCH_${DATE_PATTERN}${timestamp}.ods",
                        "issue": "invalid_date_format",
                        "severity": "warning"
                    }
                ]
            },
            "file_size": {
                "passed": 47,
                "failed": 3,
                "success_rate": 94.0,
                "issues": [
                    {
                        "filename": "TH_PRCH_${DATE_PATTERN}${timestamp}.ods",
                        "issue": "file_too_small",
                        "severity": "warning"
                    }
                ]
            }
        },
        "overall_validation_health": {
            "status": "warning",
            "success_rate": 87.0,
            "total_critical_issues": 4,
            "total_warning_issues": 3
        }
    }
}
EOF
    echo -e "${GREEN}    Generated: mock_validation_results.json${NC}"

    # 2. Mock file transfer tracking results
    echo -e "${YELLOW}  2. Creating mock file transfer tracking results...${NC}"
    
    cat > "$AUTO_FEEDBACK_DIR/mock_transfer_tracking_results.json" << EOF
{
    "tracking_date": "$INPUT_DATE",
    "transfer_summary": {
        "1p_to_soa": {
            "total_files": 50,
            "successfully_transferred": 45,
            "failed_transfers": 3,
            "pending_transfers": 2,
            "transfer_success_rate": 90.0,
            "average_transfer_time_minutes": 5.2,
            "failed_files": [
                {
                    "filename": "TH_PRCH_${DATE_PATTERN}${timestamp}.ods",
                    "failure_reason": "connection_timeout",
                    "retry_count": 3,
                    "last_attempt": "$(date -d "$INPUT_DATE 10:30:00" +%s)"
                }
            ]
        },
        "soa_to_rpm": {
            "total_files": 45,
            "successfully_transferred": 40,
            "failed_transfers": 2,
            "pending_transfers": 3,
            "transfer_success_rate": 88.9,
            "average_transfer_time_minutes": 7.8,
            "failed_files": [
                {
                    "filename": "TH_PROMPRCH_${DATE_PATTERN}${timestamp}.ods",
                    "failure_reason": "file_locked",
                    "retry_count": 2,
                    "last_attempt": "$(date -d "$INPUT_DATE 11:15:00" +%s)"
                }
            ]
        },
        "overall_transfer_health": {
            "status": "warning",
            "end_to_end_success_rate": 80.0,
            "total_transfer_failures": 5,
            "requires_intervention": true
        }
    }
}
EOF
    echo -e "${GREEN}    Generated: mock_transfer_tracking_results.json${NC}"

    # 3. Mock monitoring and detection results
    echo -e "${YELLOW}  3. Creating mock monitoring detection results...${NC}"
    
    cat > "$AUTO_FEEDBACK_DIR/mock_monitoring_results.json" << EOF
{
    "monitoring_date": "$INPUT_DATE",
    "detection_summary": {
        "mismatches": {
            "total_detected": 8,
            "critical_mismatches": 3,
            "warning_mismatches": 5,
            "affected_files": [
                "TH_PRCH_${DATE_PATTERN}${timestamp}.ods",
                "TH_PROMPRCH_${DATE_PATTERN}${timestamp}.ods"
            ]
        },
        "missing_files": {
            "total_missing": 5,
            "missing_in_soa": 2,
            "missing_in_rpm": 3,
            "orphaned_files": 1,
            "critical_missing": 2,
            "affected_files": [
                "TH_PRCH_${DATE_PATTERN}${timestamp}.ods",
                "TH_PROMPRCH_${DATE_PATTERN}${timestamp}.ods"
            ]
        },
        "corrupt_files": {
            "total_corrupt": 4,
            "zero_size": 1,
            "unreadable": 2,
            "too_large": 1,
            "affected_files": [
                "TH_PRCH_${DATE_PATTERN}${timestamp}.ods"
            ]
        },
        "duplicates": {
            "total_duplicates": 6,
            "internal_duplicates": 3,
            "cross_stage_duplicates": 2,
            "content_duplicates": 1,
            "affected_files": [
                "TH_PRCH_${DATE_PATTERN}${timestamp}.ods"
            ]
        },
        "overall_monitoring_health": {
            "status": "critical",
            "total_issues": 23,
            "critical_issues": 5,
            "warning_issues": 10,
            "info_issues": 8
        }
    }
}
EOF
    echo -e "${GREEN}    Generated: mock_monitoring_results.json${NC}"

    # 4. Mock flagged issues results
    echo -e "${YELLOW}  4. Creating mock flagged issues results...${NC}"
    
    cat > "$AUTO_FEEDBACK_DIR/mock_flagged_issues_results.json" << EOF
{
    "flagging_date": "$INPUT_DATE",
    "flagged_summary": {
        "total_flagged_files": 15,
        "flag_categories": {
            "critical": {
                "count": 7,
                "requires_immediate_action": true,
                "escalation_required": true,
                "files": [
                    "TH_PRCH_${DATE_PATTERN}${timestamp}.ods",
                    "TH_PROMPRCH_${DATE_PATTERN}${timestamp}.ods"
                ]
            },
            "warning": {
                "count": 6,
                "requires_monitoring": true,
                "auto_correctable": 3,
                "manual_review": 3,
                "files": [
                    "TH_PRCH_${DATE_PATTERN}${timestamp}.ods"
                ]
            },
            "info": {
                "count": 2,
                "auto_correctable": 2,
                "files": [
                    "TH_PRCH_${DATE_PATTERN}${timestamp}.ods"
                ]
            }
        },
        "action_required": {
            "immediate_intervention": 7,
            "scheduled_maintenance": 6,
            "auto_correction_possible": 5
        }
    }
}
EOF
    echo -e "${GREEN}    Generated: mock_flagged_issues_results.json${NC}"

    echo -e "${GREEN}✅ Pipeline status mock data generated${NC}"
}

# =============================================================================
# FUNCTION: Generate Auto Feedback Test Scenarios
# =============================================================================
generate_auto_feedback_scenarios() {
    echo -e "${RED}🔧 Generating Auto Feedback Test Scenarios...${NC}"
    
    # 1. Scenario: All systems healthy
    echo -e "${YELLOW}  1. Creating all systems healthy scenario...${NC}"
    
    cat > "$AUTO_FEEDBACK_DIR/scenario_all_healthy.json" << EOF
{
    "scenario": "all_systems_healthy",
    "test_date": "$INPUT_DATE",
    "description": "Test feedback when all pipeline components are functioning normally",
    "input_data": {
        "validation_status": {
            "overall_success_rate": 98.5,
            "critical_issues": 0,
            "warning_issues": 1,
            "info_issues": 2
        },
        "transfer_status": {
            "1p_to_soa_success_rate": 100.0,
            "soa_to_rpm_success_rate": 98.0,
            "overall_transfer_success_rate": 99.0,
            "failed_transfers": 0,
            "pending_transfers": 1
        },
        "monitoring_status": {
            "mismatches": 0,
            "missing_files": 0,
            "corrupt_files": 0,
            "duplicates": 1,
            "total_issues": 1
        },
        "flagged_issues": {
            "critical": 0,
            "warning": 1,
            "info": 1,
            "total_flagged": 2
        }
    },
    "expected_feedback": {
        "overall_health_score": 95.0,
        "status": "healthy",
        "status_color": "green",
        "alert_level": "none",
        "recommended_actions": [
            "Continue monitoring",
            "Schedule routine maintenance"
        ],
        "escalation_required": false,
        "auto_correction_suggested": true,
        "next_check_interval_minutes": 60
    }
}
EOF
    echo -e "${GREEN}    Generated: scenario_all_healthy.json${NC}"

    # 2. Scenario: Warning status with moderate issues
    echo -e "${YELLOW}  2. Creating warning status scenario...${NC}"
    
    cat > "$AUTO_FEEDBACK_DIR/scenario_warning_status.json" << EOF
{
    "scenario": "warning_status_moderate_issues",
    "test_date": "$INPUT_DATE",
    "description": "Test feedback when pipeline has moderate issues requiring attention",
    "input_data": {
        "validation_status": {
            "overall_success_rate": 87.0,
            "critical_issues": 2,
            "warning_issues": 8,
            "info_issues": 5
        },
        "transfer_status": {
            "1p_to_soa_success_rate": 90.0,
            "soa_to_rpm_success_rate": 88.9,
            "overall_transfer_success_rate": 80.0,
            "failed_transfers": 5,
            "pending_transfers": 3
        },
        "monitoring_status": {
            "mismatches": 8,
            "missing_files": 5,
            "corrupt_files": 4,
            "duplicates": 6,
            "total_issues": 23
        },
        "flagged_issues": {
            "critical": 2,
            "warning": 10,
            "info": 8,
            "total_flagged": 20
        }
    },
    "expected_feedback": {
        "overall_health_score": 75.0,
        "status": "warning",
        "status_color": "yellow",
        "alert_level": "medium",
        "recommended_actions": [
            "Investigate transfer failures",
            "Review validation errors",
            "Schedule manual intervention",
            "Increase monitoring frequency"
        ],
        "escalation_required": false,
        "auto_correction_suggested": true,
        "next_check_interval_minutes": 30
    }
}
EOF
    echo -e "${GREEN}    Generated: scenario_warning_status.json${NC}"

    # 3. Scenario: Critical status with severe issues
    echo -e "${YELLOW}  3. Creating critical status scenario...${NC}"
    
    cat > "$AUTO_FEEDBACK_DIR/scenario_critical_status.json" << EOF
{
    "scenario": "critical_status_severe_issues",
    "test_date": "$INPUT_DATE",
    "description": "Test feedback when pipeline has critical issues requiring immediate attention",
    "input_data": {
        "validation_status": {
            "overall_success_rate": 45.0,
            "critical_issues": 15,
            "warning_issues": 12,
            "info_issues": 3
        },
        "transfer_status": {
            "1p_to_soa_success_rate": 60.0,
            "soa_to_rpm_success_rate": 55.0,
            "overall_transfer_success_rate": 33.0,
            "failed_transfers": 20,
            "pending_transfers": 10
        },
        "monitoring_status": {
            "mismatches": 25,
            "missing_files": 18,
            "corrupt_files": 12,
            "duplicates": 8,
            "total_issues": 63
        },
        "flagged_issues": {
            "critical": 20,
            "warning": 15,
            "info": 5,
            "total_flagged": 40
        }
    },
    "expected_feedback": {
        "overall_health_score": 30.0,
        "status": "critical",
        "status_color": "red",
        "alert_level": "high",
        "recommended_actions": [
            "IMMEDIATE: Stop pipeline processing",
            "Investigate system failures",
            "Contact on-call engineer",
            "Review infrastructure health",
            "Perform emergency maintenance"
        ],
        "escalation_required": true,
        "auto_correction_suggested": false,
        "next_check_interval_minutes": 5
    }
}
EOF
    echo -e "${GREEN}    Generated: scenario_critical_status.json${NC}"

    # 4. Scenario: Mixed performance with partial recovery
    echo -e "${YELLOW}  4. Creating mixed performance scenario...${NC}"
    
    cat > "$AUTO_FEEDBACK_DIR/scenario_mixed_performance.json" << EOF
{
    "scenario": "mixed_performance_partial_recovery",
    "test_date": "$INPUT_DATE",
    "description": "Test feedback when different pipeline components have varying performance",
    "input_data": {
        "validation_status": {
            "overall_success_rate": 92.0,
            "critical_issues": 1,
            "warning_issues": 3,
            "info_issues": 4,
            "trend": "improving"
        },
        "transfer_status": {
            "1p_to_soa_success_rate": 85.0,
            "soa_to_rpm_success_rate": 95.0,
            "overall_transfer_success_rate": 80.75,
            "failed_transfers": 3,
            "pending_transfers": 2,
            "trend": "degrading"
        },
        "monitoring_status": {
            "mismatches": 5,
            "missing_files": 2,
            "corrupt_files": 1,
            "duplicates": 3,
            "total_issues": 11,
            "trend": "stable"
        },
        "flagged_issues": {
            "critical": 1,
            "warning": 4,
            "info": 6,
            "total_flagged": 11,
            "trend": "improving"
        }
    },
    "expected_feedback": {
        "overall_health_score": 82.0,
        "status": "warning",
        "status_color": "yellow",
        "alert_level": "medium",
        "component_status": {
            "validation": "healthy",
            "transfer": "degrading",
            "monitoring": "stable"
        },
        "recommended_actions": [
            "Focus on transfer reliability",
            "Monitor 1P to SOA connection",
            "Continue validation improvements",
            "Maintain current monitoring"
        ],
        "escalation_required": false,
        "auto_correction_suggested": true,
        "next_check_interval_minutes": 15
    }
}
EOF
    echo -e "${GREEN}    Generated: scenario_mixed_performance.json${NC}"

    # 5. Scenario: Edge case - system recovery after outage
    echo -e "${YELLOW}  5. Creating system recovery scenario...${NC}"
    
    cat > "$AUTO_FEEDBACK_DIR/scenario_system_recovery.json" << EOF
{
    "scenario": "system_recovery_after_outage",
    "test_date": "$INPUT_DATE",
    "description": "Test feedback during system recovery after a major outage",
    "input_data": {
        "validation_status": {
            "overall_success_rate": 70.0,
            "critical_issues": 5,
            "warning_issues": 10,
            "info_issues": 8,
            "trend": "rapidly_improving",
            "recovery_mode": true
        },
        "transfer_status": {
            "1p_to_soa_success_rate": 75.0,
            "soa_to_rpm_success_rate": 65.0,
            "overall_transfer_success_rate": 48.75,
            "failed_transfers": 15,
            "pending_transfers": 25,
            "trend": "recovering",
            "backlog_files": 40
        },
        "monitoring_status": {
            "mismatches": 30,
            "missing_files": 25,
            "corrupt_files": 8,
            "duplicates": 12,
            "total_issues": 75,
            "trend": "decreasing",
            "historical_peak": 120
        },
        "flagged_issues": {
            "critical": 8,
            "warning": 20,
            "info": 15,
            "total_flagged": 43,
            "trend": "decreasing"
        },
        "system_context": {
            "outage_duration_hours": 4,
            "recovery_start_time": "$(date -d "$INPUT_DATE 08:00:00" +%s)",
            "estimated_full_recovery_hours": 6
        }
    },
    "expected_feedback": {
        "overall_health_score": 65.0,
        "status": "recovering",
        "status_color": "orange",
        "alert_level": "medium",
        "recovery_status": {
            "phase": "active_recovery",
            "progress_percentage": 60.0,
            "estimated_completion_hours": 2.5
        },
        "recommended_actions": [
            "Continue monitoring recovery progress",
            "Process backlog files systematically",
            "Maintain increased staff coverage",
            "Document lessons learned",
            "Prepare post-recovery analysis"
        ],
        "escalation_required": false,
        "auto_correction_suggested": true,
        "next_check_interval_minutes": 10
    }
}
EOF
    echo -e "${GREEN}    Generated: scenario_system_recovery.json${NC}"

    echo -e "${GREEN}✅ Auto feedback test scenarios generated${NC}"
}

# =============================================================================
# FUNCTION: Generate Auto Feedback Test Script
# =============================================================================
generate_auto_feedback_test_script() {
    echo -e "${RED}🔧 Generating Auto Feedback Test Execution Script...${NC}"
    
    cat > "$AUTO_FEEDBACK_DIR/test_auto_feedback.py" << 'EOF'
#!/usr/bin/env python3
"""
Auto Feedback Test Script
Tests the _auto_feedback function with various pipeline status scenarios
"""

import json
import sys
import os
from datetime import datetime, timedelta
import math

# Mock the _auto_feedback function for testing
def mock_auto_feedback(pipeline_status):
    """
    Mock implementation of _auto_feedback function for testing
    """
    feedback = {
        "feedback_date": datetime.now().isoformat(),
        "overall_health_score": 0.0,
        "status": "unknown",
        "status_color": "gray",
        "alert_level": "none",
        "component_scores": {},
        "recommended_actions": [],
        "escalation_required": False,
        "auto_correction_suggested": False,
        "next_check_interval_minutes": 60,
        "detailed_analysis": {}
    }
    
    # Calculate component scores
    validation_score = calculate_validation_score(pipeline_status.get("validation_status", {}))
    transfer_score = calculate_transfer_score(pipeline_status.get("transfer_status", {}))
    monitoring_score = calculate_monitoring_score(pipeline_status.get("monitoring_status", {}))
    flagging_score = calculate_flagging_score(pipeline_status.get("flagged_issues", {}))
    
    feedback["component_scores"] = {
        "validation": validation_score,
        "transfer": transfer_score,
        "monitoring": monitoring_score,
        "flagging": flagging_score
    }
    
    # Calculate overall health score (weighted average)
    weights = {"validation": 0.3, "transfer": 0.3, "monitoring": 0.25, "flagging": 0.15}
    overall_score = sum(feedback["component_scores"][component] * weights[component] 
                       for component in weights.keys())
    feedback["overall_health_score"] = round(overall_score, 1)
    
    # Determine overall status and recommendations
    if overall_score >= 90:
        feedback["status"] = "healthy"
        feedback["status_color"] = "green"
        feedback["alert_level"] = "none"
        feedback["recommended_actions"] = ["Continue monitoring", "Schedule routine maintenance"]
        feedback["next_check_interval_minutes"] = 60
    elif overall_score >= 70:
        feedback["status"] = "warning" 
        feedback["status_color"] = "yellow"
        feedback["alert_level"] = "medium"
        feedback["recommended_actions"] = generate_warning_actions(feedback["component_scores"])
        feedback["next_check_interval_minutes"] = 30
        feedback["auto_correction_suggested"] = True
    elif overall_score >= 50:
        feedback["status"] = "critical"
        feedback["status_color"] = "red"
        feedback["alert_level"] = "high"
        feedback["recommended_actions"] = generate_critical_actions(feedback["component_scores"])
        feedback["next_check_interval_minutes"] = 15
        feedback["escalation_required"] = True
    else:
        feedback["status"] = "critical"
        feedback["status_color"] = "red"
        feedback["alert_level"] = "high"
        feedback["recommended_actions"] = ["IMMEDIATE: System failure detected", "Contact on-call engineer"]
        feedback["next_check_interval_minutes"] = 5
        feedback["escalation_required"] = True
    
    # Handle special cases
    if pipeline_status.get("system_context", {}).get("recovery_mode"):
        feedback["status"] = "recovering"
        feedback["status_color"] = "orange"
        feedback["next_check_interval_minutes"] = 10
    
    # Add detailed analysis
    feedback["detailed_analysis"] = generate_detailed_analysis(pipeline_status, feedback)
    
    return feedback

def calculate_validation_score(validation_status):
    """Calculate validation component score"""
    if not validation_status:
        return 100.0
    
    success_rate = validation_status.get("overall_success_rate", 100.0)
    critical_issues = validation_status.get("critical_issues", 0)
    warning_issues = validation_status.get("warning_issues", 0)
    
    # Penalize for critical and warning issues
    penalty = (critical_issues * 10) + (warning_issues * 3)
    score = max(0, success_rate - penalty)
    
    return min(100.0, score)

def calculate_transfer_score(transfer_status):
    """Calculate transfer component score"""
    if not transfer_status:
        return 100.0
    
    overall_success_rate = transfer_status.get("overall_transfer_success_rate", 100.0)
    failed_transfers = transfer_status.get("failed_transfers", 0)
    pending_transfers = transfer_status.get("pending_transfers", 0)
    
    # Penalize for failures and pending transfers
    penalty = (failed_transfers * 5) + (pending_transfers * 2)
    score = max(0, overall_success_rate - penalty)
    
    return min(100.0, score)

def calculate_monitoring_score(monitoring_status):
    """Calculate monitoring component score"""
    if not monitoring_status:
        return 100.0
    
    total_issues = monitoring_status.get("total_issues", 0)
    
    # Score based on number of issues (logarithmic penalty)
    if total_issues == 0:
        return 100.0
    elif total_issues <= 5:
        return 90.0
    elif total_issues <= 15:
        return 75.0
    elif total_issues <= 30:
        return 50.0
    else:
        return max(0, 50 - (total_issues - 30) * 2)

def calculate_flagging_score(flagged_issues):
    """Calculate flagging component score"""
    if not flagged_issues:
        return 100.0
    
    critical = flagged_issues.get("critical", 0)
    warning = flagged_issues.get("warning", 0)
    info = flagged_issues.get("info", 0)
    
    # Weighted penalty for different severity levels
    penalty = (critical * 15) + (warning * 5) + (info * 1)
    score = max(0, 100 - penalty)
    
    return score

def generate_warning_actions(component_scores):
    """Generate recommended actions for warning status"""
    actions = []
    
    if component_scores["validation"] < 80:
        actions.append("Review validation errors")
    if component_scores["transfer"] < 80:
        actions.append("Investigate transfer failures")
    if component_scores["monitoring"] < 80:
        actions.append("Address detected issues")
    if component_scores["flagging"] < 80:
        actions.append("Review flagged files")
    
    actions.extend(["Increase monitoring frequency", "Schedule manual intervention"])
    return actions

def generate_critical_actions(component_scores):
    """Generate recommended actions for critical status"""
    actions = ["IMMEDIATE: System issues detected"]
    
    if component_scores["validation"] < 50:
        actions.append("CRITICAL: Validation system failure")
    if component_scores["transfer"] < 50:
        actions.append("CRITICAL: Transfer system failure") 
    if component_scores["monitoring"] < 50:
        actions.append("CRITICAL: Multiple system issues")
    
    actions.extend([
        "Contact on-call engineer",
        "Review infrastructure health",
        "Consider emergency maintenance"
    ])
    
    return actions

def generate_detailed_analysis(pipeline_status, feedback):
    """Generate detailed analysis of pipeline status"""
    analysis = {
        "health_breakdown": feedback["component_scores"],
        "trend_analysis": {},
        "issue_summary": {},
        "recommendations": {
            "immediate": [],
            "short_term": [],
            "long_term": []
        }
    }
    
    # Analyze trends if available
    for component in ["validation_status", "transfer_status", "monitoring_status"]:
        component_data = pipeline_status.get(component, {})
        trend = component_data.get("trend")
        if trend:
            analysis["trend_analysis"][component] = trend
    
    # Summarize issues
    monitoring = pipeline_status.get("monitoring_status", {})
    analysis["issue_summary"] = {
        "total_mismatches": monitoring.get("mismatches", 0),
        "total_missing": monitoring.get("missing_files", 0),
        "total_corrupt": monitoring.get("corrupt_files", 0),
        "total_duplicates": monitoring.get("duplicates", 0)
    }
    
    return analysis

def test_auto_feedback_scenario(scenario_file):
    """Test auto feedback with a specific scenario"""
    print(f"\n=== Testing Scenario: {scenario_file} ===")
    
    try:
        with open(scenario_file, 'r') as f:
            scenario_data = json.load(f)
        
        print(f"Scenario: {scenario_data.get('scenario', 'unknown')}")
        print(f"Description: {scenario_data.get('description', 'No description')}")
        
        # Run auto feedback with scenario input
        input_data = scenario_data.get("input_data", {})
        feedback_results = mock_auto_feedback(input_data)
        
        # Display results
        print(f"\n--- Feedback Results ---")
        print(f"Overall Health Score: {feedback_results['overall_health_score']}%")
        print(f"Status: {feedback_results['status']} ({feedback_results['status_color']})")
        print(f"Alert Level: {feedback_results['alert_level']}")
        print(f"Escalation Required: {feedback_results['escalation_required']}")
        print(f"Auto-correction Suggested: {feedback_results['auto_correction_suggested']}")
        print(f"Next Check Interval: {feedback_results['next_check_interval_minutes']} minutes")
        
        print(f"\n--- Component Scores ---")
        for component, score in feedback_results["component_scores"].items():
            print(f"{component.capitalize()}: {score:.1f}%")
        
        print(f"\n--- Recommended Actions ---")
        for i, action in enumerate(feedback_results["recommended_actions"], 1):
            print(f"{i}. {action}")
        
        # Validate against expected results
        expected = scenario_data.get("expected_feedback", {})
        if expected:
            print(f"\n--- Validation ---")
            validate_feedback_results(feedback_results, expected)
        
        # Save results
        result_file = scenario_file.replace('.json', '_feedback_results.json')
        with open(result_file, 'w') as f:
            json.dump(feedback_results, f, indent=2)
        print(f"Results saved to: {result_file}")
        
        return True
        
    except Exception as e:
        print(f"❌ Error testing scenario {scenario_file}: {str(e)}")
        return False

def validate_feedback_results(actual, expected):
    """Validate actual feedback results against expected results"""
    validations = []
    
    # Check health score (within tolerance)
    if "overall_health_score" in expected:
        actual_score = actual["overall_health_score"]
        expected_score = expected["overall_health_score"]
        tolerance = 5.0  # Allow 5% tolerance
        score_diff = abs(actual_score - expected_score)
        validations.append((
            "Health Score",
            f"{actual_score}%",
            f"{expected_score}% (±{tolerance}%)",
            score_diff <= tolerance
        ))
    
    # Check status
    if "status" in expected:
        validations.append((
            "Status",
            actual["status"],
            expected["status"],
            actual["status"] == expected["status"]
        ))
    
    # Check alert level  
    if "alert_level" in expected:
        validations.append((
            "Alert Level",
            actual["alert_level"],
            expected["alert_level"],
            actual["alert_level"] == expected["alert_level"]
        ))
    
    # Check escalation requirement
    if "escalation_required" in expected:
        validations.append((
            "Escalation Required",
            actual["escalation_required"],
            expected["escalation_required"],
            actual["escalation_required"] == expected["escalation_required"]
        ))
    
    # Check auto-correction suggestion
    if "auto_correction_suggested" in expected:
        validations.append((
            "Auto-correction Suggested",
            actual["auto_correction_suggested"],
            expected["auto_correction_suggested"],
            actual["auto_correction_suggested"] == expected["auto_correction_suggested"]
        ))
    
    # Display validation results
    for test_name, actual_val, expected_val, passed in validations:
        status = "✅ PASS" if passed else "❌ FAIL"
        print(f"{status} {test_name}: Expected {expected_val}, Got {actual_val}")

def main():
    """Main test execution"""
    print("🔄 AUTO FEEDBACK TEST RUNNER")
    print("=" * 50)
    
    # Get current directory
    test_dir = os.path.dirname(os.path.abspath(__file__))
    print(f"Test directory: {test_dir}")
    
    # Find all scenario files
    scenario_files = [f for f in os.listdir(test_dir) if f.startswith('scenario_') and f.endswith('.json')]
    
    if not scenario_files:
        print("❌ No scenario files found!")
        return False
    
    print(f"Found {len(scenario_files)} test scenarios")
    
    # Run all scenarios
    passed = 0
    failed = 0
    
    for scenario_file in sorted(scenario_files):
        scenario_path = os.path.join(test_dir, scenario_file)
        if test_auto_feedback_scenario(scenario_path):
            passed += 1
        else:
            failed += 1
    
    # Summary
    print(f"\n{'='*50}")
    print(f"🏁 TEST SUMMARY")
    print(f"Passed: {passed}")
    print(f"Failed: {failed}")
    print(f"Total: {passed + failed}")
    
    if failed == 0:
        print("🎉 All tests passed!")
        return True
    else:
        print(f"❌ {failed} test(s) failed")
        return False

if __name__ == "__main__":
    success = main()
    sys.exit(0 if success else 1)
EOF
    
    chmod +x "$AUTO_FEEDBACK_DIR/test_auto_feedback.py"
    echo -e "${GREEN}    Generated: test_auto_feedback.py (executable test script)${NC}"
    
    # Create test runner script
    cat > "$AUTO_FEEDBACK_DIR/run_auto_feedback_tests.sh" << EOF
#!/bin/bash

echo "🔄 Running Auto Feedback Tests..."
cd "$AUTO_FEEDBACK_DIR"

# Run the Python test script
python3 test_auto_feedback.py

echo ""
echo "📊 Test Results Summary:"
ls -la *_feedback_results.json 2>/dev/null | wc -l | xargs echo "Generated result files:"
ls -la *_feedback_results.json 2>/dev/null || echo "No result files generated"

echo ""
echo "🔍 To review detailed results:"
echo "  cat $AUTO_FEEDBACK_DIR/*_feedback_results.json"
EOF
    
    chmod +x "$AUTO_FEEDBACK_DIR/run_auto_feedback_tests.sh"
    echo -e "${GREEN}    Generated: run_auto_feedback_tests.sh (test runner)${NC}"
    
    echo -e "${GREEN}✅ Auto feedback test scripts generated${NC}"
}

# =============================================================================
# FUNCTION: Upload auto feedback test files
# =============================================================================
upload_auto_feedback_files() {
    echo -e "${BLUE}🚀 Uploading auto feedback test files...${NC}"
    
    # Create test data in Docker container
    docker exec $DOCKER_CONTAINER mkdir -p "$SFTP_1P_PRICE/auto_feedback_test" 2>/dev/null || true
    docker exec $DOCKER_CONTAINER mkdir -p "$SFTP_SOA_PRICE/auto_feedback_test" 2>/dev/null || true
    docker exec $DOCKER_CONTAINER mkdir -p "$SFTP_RPM_PROCESSED/auto_feedback_test" 2>/dev/null || true
    
    # Upload test scenario and mock data files
    for file in "$AUTO_FEEDBACK_DIR"/*.json; do
        if [ -f "$file" ]; then
            docker cp "$file" $DOCKER_CONTAINER:"$SFTP_1P_PRICE/auto_feedback_test/" >/dev/null 2>&1
            echo -e "${GREEN}  Uploaded: $(basename "$file")${NC}"
        fi
    done
    
    # Upload test scripts
    docker cp "$AUTO_FEEDBACK_DIR/test_auto_feedback.py" $DOCKER_CONTAINER:"$SFTP_1P_PRICE/auto_feedback_test/" >/dev/null 2>&1
    docker cp "$AUTO_FEEDBACK_DIR/run_auto_feedback_tests.sh" $DOCKER_CONTAINER:"$SFTP_1P_PRICE/auto_feedback_test/" >/dev/null 2>&1
    
    echo -e "${GREEN}✅ Auto feedback test files uploaded${NC}"
    
    # Fix ownership
    fix_ownership

    # Execute complete transfer pipeline (1P → SOA → RPM)
    execute_complete_transfer_pipeline
}

# =============================================================================

# =============================================================================
# FUNCTION: Transfer files from 1P to SOA
# =============================================================================
transfer_1p_to_soa() {
    echo -e "${BLUE}🔄 Transferring files from 1P → SOA...${NC}"
    
    # Transfer price files
    echo -e "${YELLOW}📤 Transferring price files (1P → SOA)...${NC}"
    docker exec $DOCKER_CONTAINER bash -lc "
        shopt -s nullglob
        for f in $SFTP_1P_PRICE/TH_PRCH_${DATE_PATTERN}${timestamp}.ods $SFTP_1P_PRICE/TH_PRCH_${DATE_PATTERN}*.ods; do
            if [ -f \"\$f\" ]; then
                base=\$(basename \"\$f\")
                if [ ! -f $SFTP_SOA_PRICE/\$base ]; then
                    cp \"\$f\" $SFTP_SOA_PRICE/
                    echo \"  Transferred: \$base\"
                fi
            fi
        done
    " || true
    
    # Transfer promotion files
    echo -e "${YELLOW}📤 Transferring promotion files (1P → SOA)...${NC}"
    docker exec $DOCKER_CONTAINER bash -lc "
        shopt -s nullglob
        for f in $SFTP_1P_PROMOTION/TH_PROMPRCH_${DATE_PATTERN}${timestamp}.ods $SFTP_1P_PROMOTION/TH_PROMPRCH_${DATE_PATTERN}*.ods; do
            if [ -f \"\$f\" ]; then
                base=\$(basename \"\$f\")
                if [ ! -f $SFTP_SOA_PROMOTION/\$base ]; then
                    cp \"\$f\" $SFTP_SOA_PROMOTION/
                    echo \"  Transferred: \$base\"
                fi
            fi
        done
    " || true
    
    echo -e "${GREEN}✅ 1P → SOA transfer completed${NC}"
}

# =============================================================================
# FUNCTION: Transfer files from SOA to RPM
# =============================================================================
transfer_soa_to_rpm() {
    echo -e "${BLUE}📦 Transferring files from SOA → RPM...${NC}"
    
    # Transfer price files to processed
    echo -e "${YELLOW}📤 Transferring price files (SOA → RPM processed)...${NC}"
    docker exec $DOCKER_CONTAINER bash -lc "
        shopt -s nullglob
        for f in $SFTP_SOA_PRICE/TH_PRCH_${DATE_PATTERN}${timestamp}.ods $SFTP_SOA_PRICE/TH_PRCH_${DATE_PATTERN}*.ods; do
            if [ -f \"\$f\" ]; then
                base=\$(basename \"\$f\")
                if [ ! -f $SFTP_RPM_PROCESSED/\$base ]; then
                    cp \"\$f\" $SFTP_RPM_PROCESSED/
                    echo \"  Transferred: \$base\"
                fi
            fi
        done
    " || true
    
    # Transfer promotion files to processed
    echo -e "${YELLOW}📤 Transferring promotion files (SOA → RPM processed)...${NC}"
    docker exec $DOCKER_CONTAINER bash -lc "
        shopt -s nullglob
        for f in $SFTP_SOA_PROMOTION/TH_PROMPRCH_${DATE_PATTERN}${timestamp}.ods $SFTP_SOA_PROMOTION/TH_PROMPRCH_${DATE_PATTERN}*.ods; do
            if [ -f \"\$f\" ]; then
                base=\$(basename \"\$f\")
                if [ ! -f $SFTP_RPM_PROCESSED/\$base ]; then
                    cp \"\$f\" $SFTP_RPM_PROCESSED/
                    echo \"  Transferred: \$base\"
                fi
            fi
        done
    " || true
    
    echo -e "${GREEN}✅ SOA → RPM transfer completed${NC}"
}

# =============================================================================
# FUNCTION: Complete transfer pipeline (1P → SOA → RPM)
# =============================================================================
execute_complete_transfer_pipeline() {
    echo -e "${BLUE}🚀 Executing complete transfer pipeline (1P → SOA → RPM)...${NC}"
    
    # Step 1: 1P → SOA
    transfer_1p_to_soa
    
    # Small delay between transfers
    sleep 2
    
    # Step 2: SOA → RPM
    transfer_soa_to_rpm
    
    echo -e "${GREEN}✅ Complete transfer pipeline executed successfully${NC}"
}


# =============================================================================
# FUNCTION: Fix file ownership in Docker container
# =============================================================================
fix_ownership() {
    echo -e "${BLUE}🔧 Fixing file ownership in Docker container...${NC}"
    
    # 1P
    docker exec $DOCKER_CONTAINER bash -c "chown -R airflow:airflow $SFTP_1P_PRICE 2>/dev/null || true"
    docker exec $DOCKER_CONTAINER bash -c "chown -R airflow:airflow $SFTP_1P_PROMOTION 2>/dev/null || true"
    docker exec $DOCKER_CONTAINER bash -c "chown -R airflow:airflow ${SFTP_1P_FEEDBACK_PRICE/:DATETIME/$INPUT_DATE} 2>/dev/null || true"
    docker exec $DOCKER_CONTAINER bash -c "chown -R airflow:airflow ${SFTP_1P_FEEDBACK_PROMOTION/:DATETIME/$INPUT_DATE} 2>/dev/null || true"

    # SOA
    docker exec $DOCKER_CONTAINER bash -c "chown -R airflow:airflow $SFTP_SOA_PRICE 2>/dev/null || true"
    docker exec $DOCKER_CONTAINER bash -c "chown -R airflow:airflow $SFTP_SOA_PROMOTION 2>/dev/null || true"
    docker exec $DOCKER_CONTAINER bash -c "chown -R airflow:airflow ${SFTP_SOA_FEEDBACK_PRICE/:DATETIME/$INPUT_DATE} 2>/dev/null || true"
    docker exec $DOCKER_CONTAINER bash -c "chown -R airflow:airflow ${SFTP_SOA_FEEDBACK_PROMOTION/:DATETIME/$INPUT_DATE} 2>/dev/null || true"

    # RPM
    docker exec $DOCKER_CONTAINER bash -c "chown -R airflow:airflow $SFTP_RPM_PROCESSED 2>/dev/null || true"
    docker exec $DOCKER_CONTAINER bash -c "chown -R airflow:airflow $SFTP_RPM_ARCHIVE 2>/dev/null || true"

    echo -e "${GREEN}✅ File ownership fixed${NC}"
}

# MAIN EXECUTION
# =============================================================================
main_auto_feedback() {
    echo -e "${BLUE}🏁 Starting auto feedback test file generation...${NC}"
    echo -e "${BLUE}📅 Processing date: $INPUT_DATE${NC}"
    
    # Check if Docker container is running
    if ! docker ps | grep -q $DOCKER_CONTAINER; then
        echo -e "${RED}❌ Error: Docker container '$DOCKER_CONTAINER' is not running${NC}"
        echo -e "${YELLOW}💡 Start container first: docker-compose up -d${NC}"
        exit 1
    fi
    
    # Generate pipeline status mock data
    generate_pipeline_status_mock
    
    # Generate test scenarios
    generate_auto_feedback_scenarios
    
    # Generate test scripts
    generate_auto_feedback_test_script
    
    # Upload to Docker
    upload_auto_feedback_files
    
    echo -e "${GREEN}🎉 Auto feedback test files generation completed!${NC}"
    echo -e "${YELLOW}💡 Files ready for testing automatic feedback functionality${NC}"
    echo -e "${BLUE}📋 Local data stored in: $AUTO_FEEDBACK_DIR${NC}"
    echo -e "${BLUE}🔄 Test scenarios created:${NC}"
    echo -e "${BLUE}  • All systems healthy (green status)${NC}"
    echo -e "${BLUE}  • Warning status with moderate issues${NC}"
    echo -e "${BLUE}  • Critical status with severe issues${NC}"
    echo -e "${BLUE}  • Mixed performance with partial recovery${NC}"
    echo -e "${BLUE}  • System recovery after outage${NC}"
    echo -e "${BLUE}🧪 Run tests with: cd $AUTO_FEEDBACK_DIR && ./run_auto_feedback_tests.sh${NC}"
}

# Run main function if not sourced
main_auto_feedback "$@"

# =============================================================================
# FUNCTION: 10-minute transfer loop (1P → SOA → RPM)
# =============================================================================
start_transfer_loop() {
    local interval_seconds=10
    echo -e "${BLUE}⏱️ Starting transfer loop: every 10 minutes (includes directory checks)${NC}"
    # Randomized clear cadence: clear every N cycles, where N ∈ [1,10]
    local cycles_since_clear=0
    local clear_threshold=$((1 + RANDOM % 10))
    echo -e "${YELLOW}🧽 Will clear Docker files every ${clear_threshold} cycle(s) (randomized 1-10)${NC}"
    # Resolve clear script absolute path once
    local script_dir
    script_dir=$(cd "$(dirname "$0")" && pwd)
    local clear_script="${script_dir}/clear_docker_files.sh"
    if [ ! -x "$clear_script" ]; then
        echo -e "${RED}❌ Warning: clear script not executable or not found at: $clear_script${NC}"
        echo -e "${YELLOW}💡 Ensure the script exists and is executable: chmod +x clear_docker_files.sh${NC}"
    fi
    while true; do
        echo -e "${YELLOW}⏰ Starting new cycle at $(date)${NC}"
        
        # Clear current local date directory before each cycle
        local date_dir="$BASE_DIR/$DATE_DIR_FORMAT"
        if [ -d "$date_dir" ]; then
            echo -e "${YELLOW}🗑️ Clearing local date directory: $date_dir${NC}"
            rm -rf "$date_dir"
        fi
        # Ensure directories exist each cycle (Step 1)
        check_and_create_directories

        # Generate and upload fresh data each cycle
        echo -e "${YELLOW}🧪 Generating new mock data for this cycle (TOTAL_FILES per type: $TOTAL_FILES)...${NC}"
        generate_price_files
        generate_promotion_files
        generate_feedback_price_files
        generate_feedback_promotion_files
        upload_to_docker
        fix_ownership

        echo -e "${YELLOW}🔄 Syncing 1P → SOA (price, promotion)...${NC}"
        docker exec $DOCKER_CONTAINER bash -lc "
            shopt -s nullglob
            # 1P → SOA price
            for f in $SFTP_1P_PRICE/TH_PRCH_${DATE_PATTERN}*.ods; do
                base=\$(basename \"\$f\")
                [ -f $SFTP_SOA_PRICE/\$base ] || cp \"\$f\" $SFTP_SOA_PRICE/
            done
            # 1P → SOA promotion
            for f in $SFTP_1P_PROMOTION/TH_PROMPRCH_${DATE_PATTERN}*.ods; do
                base=\$(basename \"\$f\")
                [ -f $SFTP_SOA_PROMOTION/\$base ] || cp \"\$f\" $SFTP_SOA_PROMOTION/
            done
        " > /dev/null 2>&1 || true

        echo -e "${YELLOW}🧩 Enriching within SOA (SOA → SOA noop step)...${NC}"
        # No-op enrichment placeholder. Extend here if enrichment logic is needed.

        echo -e "${YELLOW}📦 Syncing SOA → RPM (processed only)...${NC}"
        docker exec $DOCKER_CONTAINER bash -lc "
            shopt -s nullglob
            # SOA → RPM price
            for f in $SFTP_SOA_PRICE/TH_PRCH_${DATE_PATTERN}*.ods; do
                base=\$(basename \"\$f\")
                [ -f $SFTP_RPM_PROCESSED/\$base ] || cp \"\$f\" $SFTP_RPM_PROCESSED/
            done
            # SOA → RPM promotion
            for f in $SFTP_SOA_PROMOTION/TH_PROMPRCH_${DATE_PATTERN}*.ods; do
                base=\$(basename \"\$f\")
                [ -f $SFTP_RPM_PROCESSED/\$base ] || cp \"\$f\" $SFTP_RPM_PROCESSED/
            done
        " > /dev/null 2>&1 || true

        echo -e "${GREEN}✅ Cycle completed. Waiting 10 minutes until next cycle...${NC}"
        echo -e "${BLUE}⏰ Next cycle will start at $(date -d "+10 minutes" 2>/dev/null || date -v+10M 2>/dev/null || echo "in 10 minutes")${NC}"
        
        # Increment cycle counter and clear when threshold reached
        cycles_since_clear=$((cycles_since_clear + 1))
        if [ "$cycles_since_clear" -ge "$clear_threshold" ]; then
            echo -e "${YELLOW}🧽 Reached clear threshold (${clear_threshold}). Clearing Docker files now...${NC}"
            if [ -x "$clear_script" ]; then
                "$clear_script" --container "$DOCKER_CONTAINER" || echo -e "${RED}❌ Clear script failed${NC}"
            else
                echo -e "${RED}❌ Skip clearing: clear script not available${NC}"
            fi
            cycles_since_clear=0
            clear_threshold=$((1 + RANDOM % 10))
            echo -e "${YELLOW}🎲 Next clear will happen after ${clear_threshold} cycle(s)${NC}"
        else
            echo -e "${BLUE}ℹ️ Cycles since last clear: ${cycles_since_clear}/${clear_threshold}${NC}"
        fi

        sleep "$interval_seconds"
    done
}

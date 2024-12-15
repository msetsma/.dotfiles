"""
--- Pipeline Pattern ---
Use Case: Chain multiple stages of data processing in a sequence.
Example: Data validation, transformation, and enrichment pipelines.
Description: The Pipeline Pattern passes data through a series of processing stages (functions or classes),
where each stage transforms the data and passes it to the next stage.
"""

class PipelineStage:
    def __init__(self, next_stage=None):
        self.next_stage = next_stage

    def process(self, data):
        if self.next_stage:
            return self.next_stage.process(data)
        return data

class ValidateStage(PipelineStage):
    def process(self, data):
        if not isinstance(data, dict):
            raise ValueError("Data must be a dictionary")
        print("Validation passed")
        return super().process(data)

class TransformStage(PipelineStage):
    def process(self, data):
        print("Transforming data")
        transformed_data = {k.upper(): v for k, v in data.items()}
        return super().process(transformed_data)

class EnrichStage(PipelineStage):
    def process(self, data):
        print("Enriching data")
        enriched_data = data.copy()
        enriched_data["ENRICHED"] = True
        return super().process(enriched_data)

class OutputStage(PipelineStage):
    def process(self, data):
        print("Final Output:", data)
        return data

# Example usage
def main():
    # Create pipeline stages
    pipeline = ValidateStage(
        TransformStage(
            EnrichStage(
                OutputStage()
            )
        )
    )

    # Input data
    data = {"name": "Alice", "age": 30}

    # Process data through the pipeline
    try:
        pipeline.process(data)
    except Exception as e:
        print(f"Pipeline error: {e}")

if __name__ == "__main__":
    main()

# Output:
# Validation passed
# Transforming data
# Enriching data
# Final Output: {'NAME': 'Alice', 'AGE': 30, 'ENRICHED': True}
